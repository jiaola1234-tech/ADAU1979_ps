`timescale 1 ps / 1 ps

// Top-level wrapper for the PS-IIC/EMIO diagnostic design.
// The *_I/O/T ports are intentionally kept separate at the BD boundary so
// that each I2C line is implemented as an open-drain IOBUF in the PL.
module ps_iic_emio_test_wrapper (
    inout  [14:0] DDR_addr,
    inout  [2:0]  DDR_ba,
    inout         DDR_cas_n,
    inout         DDR_ck_n,
    inout         DDR_ck_p,
    inout         DDR_cke,
    inout         DDR_cs_n,
    inout  [3:0]  DDR_dm,
    inout  [31:0] DDR_dq,
    inout  [3:0]  DDR_dqs_n,
    inout  [3:0]  DDR_dqs_p,
    inout         DDR_odt,
    inout         DDR_ras_n,
    inout         DDR_reset_n,
    inout         DDR_we_n,
    inout         FIXED_IO_ddr_vrn,
    inout         FIXED_IO_ddr_vrp,
    inout  [53:0] FIXED_IO_mio,
    inout         FIXED_IO_ps_clk,
    inout         FIXED_IO_ps_porb,
    inout         FIXED_IO_ps_srstb,
    inout         adau_scl,
    inout         adau_sda,
    output        adau_pd_rst
);

    wire i2c0_scl_i;
    wire i2c0_scl_o;
    wire i2c0_scl_t;
    wire i2c0_sda_i;
    wire i2c0_sda_o;
    wire i2c0_sda_t;

    // Xilinx IOBUF implements the required open-drain behavior when the PS
    // IIC controller drives *_O=0 or releases the line with *_T=1.
    IOBUF iobuf_scl (
        .I  (i2c0_scl_o),
        .O  (i2c0_scl_i),
        .T  (i2c0_scl_t),
        .IO (adau_scl)
    );

    IOBUF iobuf_sda (
        .I  (i2c0_sda_o),
        .O  (i2c0_sda_i),
        .T  (i2c0_sda_t),
        .IO (adau_sda)
    );

    // The test project does not own ADAU audio reset sequencing. Hold the
    // device released; the board-level reset/power wiring must also be valid.
    assign adau_pd_rst = 1'b1;

    design_1 design_1_i (
        .DDR_addr       (DDR_addr),
        .DDR_ba         (DDR_ba),
        .DDR_cas_n      (DDR_cas_n),
        .DDR_ck_n       (DDR_ck_n),
        .DDR_ck_p       (DDR_ck_p),
        .DDR_cke        (DDR_cke),
        .DDR_cs_n       (DDR_cs_n),
        .DDR_dm         (DDR_dm),
        .DDR_dq         (DDR_dq),
        .DDR_dqs_n      (DDR_dqs_n),
        .DDR_dqs_p      (DDR_dqs_p),
        .DDR_odt        (DDR_odt),
        .DDR_ras_n      (DDR_ras_n),
        .DDR_reset_n    (DDR_reset_n),
        .DDR_we_n       (DDR_we_n),
        .FIXED_IO_ddr_vrn (FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp (FIXED_IO_ddr_vrp),
        .FIXED_IO_mio    (FIXED_IO_mio),
        .FIXED_IO_ps_clk (FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .i2c0_scl_i     (i2c0_scl_i),
        .i2c0_scl_o     (i2c0_scl_o),
        .i2c0_scl_t     (i2c0_scl_t),
        .i2c0_sda_i     (i2c0_sda_i),
        .i2c0_sda_o     (i2c0_sda_o),
        .i2c0_sda_t     (i2c0_sda_t)
    );
endmodule

