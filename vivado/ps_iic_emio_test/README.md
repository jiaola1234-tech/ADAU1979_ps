# PS IIC through PL EMIO — ADAU1979 test project

This is a small diagnostic project for the AX7020 (`xc7z020clg400-2`). It
enables Zynq PS IIC0, routes it through EMIO, and puts an IOBUF on the PL side
before the signals reach the ADAU1979 header:

```text
PS IIC0 -> EMIO (SCL/SDA I/O/T) -> PL IOBUF -> J10-3/J10-4
```

It is intentionally separate from the existing PL Verilog I2C master. The
purpose is to distinguish a board/address/reset problem from a bug in the
existing RTL I2C state machine.

## Create the Vivado project

Run `scripts/create_ps_iic_emio_test.tcl` from Vivado 2022.2. The script
creates `ps_iic_emio_test.xpr`, copies the known-good AX7020 PS/DDR template
from `vivado/adau1979_lwip`, removes the existing capture/I2C logic, enables
PS IIC0 on EMIO, and adds the three-signal EMIO-to-IOBUF wiring.

The script does not overwrite the original project. After opening the new
project, run Block Design validation, synthesis, implementation, and generate
the bitstream in the normal Vivado flow. The expected PL pins are in
`constraints/ps_iic_emio_test.xdc`.

## Software check

`vitis/ps_iic_emio_test.c` is a standalone Vitis example using `XIicPs`.
It initializes IIC0 at 100 kHz, writes and reads ADAU1979 register `0x01`,
and reports the result on PS UART1. Update the two address constants if the
board straps differ (`0x11` and `0x31` are the current design assumptions).

The readback result is useful even when the PLL is not locked: a successful
read proves that PS IIC, EMIO, IOBUF, pull-ups, power, reset, and the address
path are working. A timeout/NACK points to the physical path or address before
the existing Verilog initialization logic is investigated.

## Electrical requirements

* ADAU1979 H4-1 (SCL) -> AX7020 J10-3, and H4-2 (SDA) -> J10-4.
* The lines must have 3.3 V pull-ups and share ground with AX7020.
* ADAU PD/RST must be released high (H4-9 -> J10-11 / Y14).
* Do not connect a 5 V pull-up to the FPGA pins.

