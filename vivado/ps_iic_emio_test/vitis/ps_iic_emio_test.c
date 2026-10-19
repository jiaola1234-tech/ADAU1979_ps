#include "xparameters.h"
#include "xiicps.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

#ifndef XPAR_XIICPS_0_DEVICE_ID
#error "The generated platform does not contain PS IIC0. Check EMIO/PS configuration."
#endif

#define IIC_DEVICE_ID XPAR_XIICPS_0_DEVICE_ID
#define IIC_SCLK_HZ   100000U
#define ADAU_U1_ADDR  0x11U
#define ADAU_U2_ADDR  0x31U
#define ADAU_PLL_REG  0x01U

static XIicPs Iic;

static int adau_read8(u8 address, u8 reg, u8 *value)
{
    int status;

    // A register pointer followed by a receive is the standard ADAU1979
    // register read sequence. The driver emits a repeated start when the
    // option is enabled.
    XIicPs_SetOptions(&Iic, XIICPS_7_BIT_ADDR_OPTION |
                             XIICPS_REP_START_OPTION);

    status = XIicPs_MasterSendPolled(&Iic, &reg, 1, address);
    if (status != XST_SUCCESS)
        return status;

    status = XIicPs_MasterRecvPolled(&Iic, value, 1, address);
    XIicPs_ClearOptions(&Iic, XIICPS_REP_START_OPTION);
    return status;
}

static int adau_write8(u8 address, u8 reg, u8 value)
{
    u8 tx[2] = {reg, value};
    XIicPs_ClearOptions(&Iic, XIICPS_REP_START_OPTION);
    return XIicPs_MasterSendPolled(&Iic, tx, sizeof(tx), address);
}

static void probe(u8 address)
{
    u8 value = 0;
    int status;

    xil_printf("PS IIC probe address 0x%02x\r\n", address);
    status = adau_read8(address, ADAU_PLL_REG, &value);
    xil_printf("  read PLL_CONTROL: status=%d value=0x%02x\r\n",
               status, value);

    // This write/read pair is deliberately conservative: it writes the
    // existing value back, so it does not change PLL configuration.
    if (status == XST_SUCCESS) {
        status = adau_write8(address, ADAU_PLL_REG, value);
        xil_printf("  write same value: status=%d\r\n", status);
    }
}

int main(void)
{
    XIicPs_Config *config;
    int status;

    xil_printf("ADAU1979 PS IIC EMIO test\r\n");
    xil_printf("IIC0 -> EMIO -> PL IOBUF -> J10-3/J10-4\r\n");

    config = XIicPs_LookupConfig(IIC_DEVICE_ID);
    if (config == NULL) {
        xil_printf("ERROR: XIicPs_LookupConfig failed\r\n");
        return XST_FAILURE;
    }

    status = XIicPs_CfgInitialize(&Iic, config, config->BaseAddress);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: IIC init failed: %d\r\n", status);
        return status;
    }

    status = XIicPs_SetSClk(&Iic, IIC_SCLK_HZ);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: IIC clock setup failed: %d\r\n", status);
        return status;
    }

    probe(ADAU_U1_ADDR);
    probe(ADAU_U2_ADDR);
    xil_printf("PS IIC EMIO test complete\r\n");
    return XST_SUCCESS;
}

