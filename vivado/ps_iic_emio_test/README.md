# 通过 PL EMIO 转发 PS IIC —— ADAU1979 测试工程

本工程是一个面向 AX7020（`xc7z020clg400-2`）的小型诊断工程。它使能 Zynq 的
PS IIC0，经 EMIO 引出，并在 PL 侧加入 IOBUF，然后信号才到达 ADAU1979 的排针：

```text
PS IIC0 -> EMIO (SCL/SDA I/O/T) -> PL IOBUF -> J10-3/J10-4
```

本工程有意与已有的 PL 侧 Verilog I2C master 相互独立，目的是把「板级 / 地址 /
复位问题」与「现有 RTL I2C 状态机的缺陷」区分开。

## 创建 Vivado 工程

在 Vivado 2022.2 中运行 `scripts/create_ps_iic_emio_test.tcl`。该脚本会创建
`ps_iic_emio_test.xpr`，从 `vivado/adau1979_lwip` 复制已验证可用的 AX7020
PS/DDR 模板，移除原有的采集 / I2C 逻辑，使能 PS IIC0 的 EMIO，并补齐三路
EMIO 到 IOBUF 的连线。

该脚本不会覆盖原工程。打开新工程后，按常规 Vivado 流程执行 Block Design 校验、
综合、实现并生成 bitstream。预期的 PL 引脚约束位于
`constraints/ps_iic_emio_test.xdc`。

## 软件验证

`vitis/ps_iic_emio_test.c` 是一个基于 `XIicPs` 的独立 Vitis 例程。它将 IIC0
初始化为 100 kHz，写入并读回 ADAU1979 寄存器 `0x01`，并通过 PS UART1 打印
结果。若板上 strap 配置与当前设计不同，请修改这两个地址常量（当前设计假设值为
`0x11` 与 `0x31`）。

即使 PLL 未锁定，读回结果依然具有参考价值：读成功可证明 PS IIC、EMIO、IOBUF、
上拉、供电、复位以及地址通路均正常；若出现超时 / NACK，则应先排查物理通路或
地址，再去查已有的 Verilog 初始化逻辑。

## 电气要求

* ADAU1979 H4-1（SCL）-> AX7020 J10-3，H4-2（SDA）-> J10-4。
* 两根信号线必须有 3.3 V 上拉，并与 AX7020 共地。
* ADAU PD/RST 必须置高释放（H4-9 -> J10-11 / Y14）。
* 禁止将 5 V 上拉接到 FPGA 引脚。
