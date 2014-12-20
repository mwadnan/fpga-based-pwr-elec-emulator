#ifndef __SYSTEM_CONFIG_H_
#define __SYSTEM_CONFIG_H_


#define FPGA_DEVICE_FAMILY    "EC"
#define PLATFORM_NAME         "wb_soc_v2"
#define USE_PLL               (0)
#define CPU_FREQUENCY         (66666700)


/* FOUND 1 CPU UNIT(S) */

/*
 * CPU Instance LM32 component configuration
 */
#define CPU_NAME "LM32"
#define CPU_EBA (0x00000000)
#define CPU_DIVIDE_ENABLED (1)
#define CPU_SIGN_EXTEND_ENABLED (1)
#define CPU_MULTIPLIER_ENABLED (1)
#define CPU_SHIFT_ENABLED (1)
#define CPU_DEBUG_ENABLED (0)
#define CPU_HW_BREAKPOINTS_ENABLED (0)
#define CPU_NUM_HW_BREAKPOINTS (0)
#define CPU_NUM_WATCHPOINTS (0)
#define CPU_ICACHE_ENABLED (0)
#define CPU_ICACHE_SETS (512)
#define CPU_ICACHE_ASSOC (1)
#define CPU_ICACHE_BYTES_PER_LINE (16)
#define CPU_DCACHE_ENABLED (0)
#define CPU_DCACHE_SETS (512)
#define CPU_DCACHE_ASSOC (1)
#define CPU_DCACHE_BYTES_PER_LINE (16)
#define CPU_DEBA (0x00000000)
#define CPU_CHARIO_IN        (0)
#define CPU_CHARIO_OUT       (0)
#define CPU_CHARIO_TYPE      "JTAG UART"

/*
 * uart component configuration
 */
#define UART_NAME  "uart"
#define UART_BASE_ADDRESS  (0x81000000)
#define UART_SIZE  (16)
#define UART_IRQ (2)
#define UART_CHARIO_IN        (1)
#define UART_CHARIO_OUT       (1)
#define UART_CHARIO_TYPE      "RS-232"
#define UART_ADDRESS_LOCK  (0)
#define UART_DISABLE  (0)
#define UART_MODEM  (0)
#define UART_WB_DAT_WIDTH  (8)
#define UART_WB_ADR_WIDTH  (4)
#define UART_BAUD_RATE  (115200)
#define UART_IB_SIZE  (4)
#define UART_OB_SIZE  (4)
#define UART_BLOCK_WRITE  (1)
#define UART_BLOCK_READ  (1)
#define UART_STDOUT_SIM  (0)
#define UART_STDOUT_SIMFAST  (0)
#define UART_RXRDY_ENABLE  (0)
#define UART_TXRDY_ENABLE  (0)
#define UART_INTERRUPT_DRIVEN  (1)
#define UART_LCR_DATA_BITS  (8)
#define UART_LCR_STOP_BITS  (1)
#define UART_LCR_PARITY_ENABLE  (0)
#define UART_LCR_PARITY_ODD  (0)
#define UART_LCR_PARITY_STICK  (0)
#define UART_LCR_SET_BREAK  (0)
#define UART_FIFO  (0)

/*
 * gpio component configuration
 */
#define GPIO_NAME  "gpio"
#define GPIO_BASE_ADDRESS  (0x82000000)
#define GPIO_SIZE  (16)
#define GPIO_CHARIO_IN        (0)
#define GPIO_CHARIO_OUT       (0)
#define GPIO_WB_DAT_WIDTH  (32)
#define GPIO_WB_ADR_WIDTH  (4)
#define GPIO_ADDRESS_LOCK  (0)
#define GPIO_DISABLE  (0)
#define GPIO_OUTPUT_PORTS_ONLY  (0)
#define GPIO_INPUT_PORTS_ONLY  (0)
#define GPIO_TRISTATE_PORTS  (0)
#define GPIO_BOTH_INPUT_AND_OUTPUT  (1)
#define GPIO_DATA_WIDTH  (1)
#define GPIO_INPUT_WIDTH  (4)
#define GPIO_OUTPUT_WIDTH  (4)
#define GPIO_IRQ_MODE  (0)
#define GPIO_LEVEL  (0)
#define GPIO_EDGE  (0)
#define GPIO_EITHER_EDGE_IRQ  (0)
#define GPIO_POSE_EDGE_IRQ  (0)
#define GPIO_NEGE_EDGE_IRQ  (0)

/*
 * slave_passthru component configuration
 */
#define SLAVE_PASSTHRU_NAME  "slave_passthru"
#define SLAVE_PASSTHRU_BASE_ADDRESS  (0x80000000)
#define SLAVE_PASSTHRU_SIZE  (16777216)
#define SLAVE_PASSTHRU_IRQ (1)
#define SLAVE_PASSTHRU_CHARIO_IN        (0)
#define SLAVE_PASSTHRU_CHARIO_OUT       (0)
#define SLAVE_PASSTHRU_ADDRESS_LOCK  (0)
#define SLAVE_PASSTHRU_DISABLE  (0)
#define SLAVE_PASSTHRU_WB_DAT_WIDTH  (32)
#define SLAVE_PASSTHRU_WB_SEL_WIDTH  (4)
#define SLAVE_PASSTHRU_WB_ADR_WIDTH  (32)


#endif /* __SYSTEM_CONFIG_H_ */
