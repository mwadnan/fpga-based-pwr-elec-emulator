#include "DDStructs.h"

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

void LatticeDDInit(void)
{

    /* initialize LM32 instance of lm32_top */
    LatticeMico32Init(&lm32_top_LM32);
    
    /* initialize uart instance of uart_core */
    MicoUartInit(&uart_core_uart);
    
    /* initialize gpio instance of gpio */
    MicoGPIOInit(&gpio_gpio);
    
    /* initialize slave_passthru instance of slave_passthru */
    MicoPassthruInit(&slave_passthru_slave_passthru);
    
    /* invoke application's main routine*/
    main();
}



#ifdef __cplusplus
};
#endif /* __cplusplus */
