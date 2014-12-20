#include "DDStructs.h"


/* lm32_top instance LM32*/
struct st_LatticeMico32Ctx_t lm32_top_LM32 = {
    "LM32"};


/* uart_core instance uart*/
  /* array declaration for rxBuffer */
   unsigned char _uart_core_uart_rxBuffer[4];
  /* array declaration for txBuffer */
   unsigned char _uart_core_uart_txBuffer[4];
struct st_MicoUartCtx_t uart_core_uart = {
    "uart",
    0x81000000,
    2,
    1,
    115200,
    8,
    1,
    4,
    4,
    1,
    1,
    0,
    _uart_core_uart_rxBuffer,
    _uart_core_uart_txBuffer,
};


/* gpio instance gpio*/
struct st_MicoGPIOCtx_t gpio_gpio = {
    "gpio",
    0x82000000,
    255,
    0,
    0,
    1,
    0,
    1,
    4,
    4,
    0,
    32,
};


/* slave_passthru instance slave_passthru*/
struct st_MicoPassthruCtx_t slave_passthru_slave_passthru = {
    "slave_passthru",
    0x80000000,
    1,
};

