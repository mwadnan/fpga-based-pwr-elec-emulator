`define LATTICE_FAMILY "EC"
`define LATTICE_FAMILY_EC
`define LATTICE_DEVICE "All"
`ifndef SYSTEM_CONF
`define SYSTEM_CONF
`timescale 1ns / 100 ps
`define CFG_EBA_RESET 32'h0
`define MULT_ENABLE
`define CFG_PL_MULTIPLY_ENABLED
`define SHIFT_ENABLE
`define CFG_PL_BARREL_SHIFT_ENABLED
`define CFG_MC_DIVIDE_ENABLED
`define CFG_SIGN_EXTEND_ENABLED
`define CFG_IROM_ENABLED
`define CFG_IROM_BASE_ADDRESS 32'h0
`define CFG_IROM_LIMIT 32'h3fff
`define CFG_IROM_INIT_FILE_FORMAT "hex"
`define CFG_IROM_INIT_FILE "none"
`define CFG_DRAM_ENABLED
`define CFG_DRAM_BASE_ADDRESS 32'h4000
`define CFG_DRAM_LIMIT 32'h47ff
`define CFG_DRAM_INIT_FILE_FORMAT "hex"
`define CFG_DRAM_INIT_FILE "none"
`define LM32_I_PC_WIDTH 15
`define uartUART_WB_DAT_WIDTH 8
`define uartUART_WB_ADR_WIDTH 4
`define uartCLK_IN_MHZ 0
`define uartBAUD_RATE 115200
`define IB_SIZE 32'h4
`define OB_SIZE 32'h4
`define BLOCK_WRITE
`define BLOCK_READ
`define INTERRUPT_DRIVEN
`define CharIODevice
`define uartLCR_DATA_BITS 8
`define uartLCR_STOP_BITS 1
`define gpioGPIO_WB_DAT_WIDTH 32
`define gpioGPIO_WB_ADR_WIDTH 4
`define gpioBOTH_INPUT_AND_OUTPUT
`define gpioDATA_WIDTH 32'h1
`define gpioINPUT_WIDTH 32'h4
`define gpioOUTPUT_WIDTH 32'h4
`define slave_passthruS_WB_DAT_WIDTH 32
`define S_WB_SEL_WIDTH 4
`define slave_passthruS_WB_ADR_WIDTH 32
`endif // SYSTEM_CONF
