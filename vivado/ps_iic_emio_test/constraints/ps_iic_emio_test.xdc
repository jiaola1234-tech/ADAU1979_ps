# AX7020 J10 / ADAU1979 H4 mapping for the PS-IIC EMIO test.
# The PS IIC signals are open-drain through the IOBUF instances in the
# top-level wrapper. Use external 3.3 V pull-ups (the ADAU board normally has
# them); do not enable a push-pull FPGA output on these nets.

set_property PACKAGE_PIN W19 [get_ports adau_scl]
set_property PACKAGE_PIN W18 [get_ports adau_sda]
set_property PACKAGE_PIN Y14 [get_ports adau_pd_rst]

set_property IOSTANDARD LVCMOS33 [get_ports adau_scl]
set_property IOSTANDARD LVCMOS33 [get_ports adau_sda]
set_property IOSTANDARD LVCMOS33 [get_ports adau_pd_rst]

# Keep the bidirectional I2C pins electrically passive while the PS IIC
# controller is reset or tri-stated.
set_property PULLTYPE NONE [get_ports adau_scl]
set_property PULLTYPE NONE [get_ports adau_sda]

