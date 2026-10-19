# Create a small PS-IIC/EMIO diagnostic project without modifying the main
# adau1979_lwip project. Tested syntax target: Vivado 2022.2.

set script_dir [file normalize [file dirname [info script]]]
set test_root  [file normalize [file join $script_dir ..]]
set repo_root  [file normalize [file join $test_root .. ..]]
set project_dir [file join $test_root project]
set project_name ps_iic_emio_test
set part xc7z020clg400-2

set template_bd_dir [file join $repo_root vivado adau1979_lwip \
    adau1979_lwip.srcs sources_1 bd design_1]
set copied_bd_dir [file join $project_dir ${project_name}.srcs sources_1 bd design_1]

if {[file exists $project_dir]} {
    puts "INFO: removing previous generated project $project_dir"
    file delete -force $project_dir
}
create_project -force $project_name $project_dir -part $part
set_property target_language Verilog [current_project]
set_property ip_repo_paths [list [file join $repo_root ip_repo]] [current_project]
update_ip_catalog

file mkdir [file dirname $copied_bd_dir]
file copy -force $template_bd_dir $copied_bd_dir

set bd_file [file join $copied_bd_dir design_1.bd]
add_files -norecurse $bd_file
set bd_obj [get_files $bd_file]
set_property used_in_synthesis true $bd_obj
set_property used_in_implementation true $bd_obj
set_property used_in_simulation true $bd_obj
open_bd_design $bd_file

set ps [get_bd_cells processing_system7_0]
if {$ps eq ""} {
    error "The copied template does not contain processing_system7_0"
}

# Keep the known-good AX7020 DDR/MIO preset from the template, but turn off
# the old AXI/PL capture design and enable PS IIC0 on EMIO. Some properties
# are version-dependent, so set them individually and report any unsupported
# optional property rather than silently changing the wiring.
proc try_ps_property {cell property value} {
    if {[catch {set_property $property $value $cell} message]} {
        puts "WARNING: could not set $property: $message"
    } else {
        puts "INFO: $property = $value"
    }
}

foreach {property value} {
    CONFIG.PCW_USE_M_AXI_GP0 0
    CONFIG.PCW_USE_S_AXI_HP0 0
    CONFIG.PCW_USE_FABRIC_INTERRUPT 0
    CONFIG.PCW_IRQ_F2P_INTR 0
    CONFIG.PCW_EN_I2C0 1
    CONFIG.PCW_EN_EMIO_I2C0 1
    CONFIG.PCW_I2C0_PERIPHERAL_ENABLE 1
    CONFIG.PCW_I2C0_I2C0_IO EMIO
} {
    try_ps_property $ps $property $value
}

# Remove all old PL logic. DDR and FIXED_IO are interface ports owned by PS7
# and are intentionally retained. Scalar external ports from the old design
# are removed before the six EMIO boundary ports are created below.
foreach cell [get_bd_cells -quiet] {
    if {[get_property NAME $cell] ne "processing_system7_0"} {
        catch {delete_bd_objs $cell}
    }
}
foreach port [get_bd_ports -quiet] {
    set port_name [get_property NAME $port]
    if {$port_name ne "DDR" && $port_name ne "FIXED_IO"} {
        catch {delete_bd_objs $port}
    }
}

proc connect_ps_emio {ps pin port_name direction} {
    set pin_obj [get_bd_pins -quiet $ps/$pin]
    if {$pin_obj eq ""} {
        error "PS7 pin $pin is missing. IIC0 EMIO was not enabled by this Vivado version."
    }
    set port_obj [create_bd_port -dir $direction $port_name]
    connect_bd_net $port_obj $pin_obj
}

connect_ps_emio $ps I2C0_SCL_I i2c0_scl_i I
connect_ps_emio $ps I2C0_SCL_O i2c0_scl_o O
connect_ps_emio $ps I2C0_SCL_T i2c0_scl_t O
connect_ps_emio $ps I2C0_SDA_I i2c0_sda_i I
connect_ps_emio $ps I2C0_SDA_O i2c0_sda_o O
connect_ps_emio $ps I2C0_SDA_T i2c0_sda_t O

validate_bd_design
save_bd_design
generate_target all [get_files $bd_file]

# Add the custom wrapper after the BD target exists. It instantiates the
# generated design_1 module and implements the PL-side IOBUFs.
set wrapper [file join $test_root src ps_iic_emio_test_wrapper.v]
add_files -norecurse $wrapper
set_property top ps_iic_emio_test_wrapper [current_fileset]
update_compile_order -fileset sources_1

set xdc [file join $test_root constraints ps_iic_emio_test.xdc]
add_files -fileset constrs_1 -norecurse $xdc

puts ""
puts "PS IIC EMIO test project created: [get_property DIRECTORY [current_project]]"
puts "Open the project, validate the BD, then synthesize/implement and generate the bitstream."
puts "The generated BD boundary must contain i2c0_scl_{i,o,t} and i2c0_sda_{i,o,t}."
close_bd_design [current_bd_design]
close_project

