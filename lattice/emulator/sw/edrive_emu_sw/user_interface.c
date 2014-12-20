/*
 * user_interface.c
 *
 *  Created on: 06.05.2013
 *      Author: Wasif
 */
#include "user_interface.h"

MicoGPIOCtx_t* gpio_ctx;

void init_user_interface ()
{
	gpio_ctx = (MicoGPIOCtx_t *) MicoGetDevice("gpio");
}

int set_LED (int ledVal){
	MICO_GPIO_WRITE_DATA(gpio_ctx, (unsigned int)ledVal);

	return 0;
}

/*
 *  Returns 1 if specified dip_switch is turned ON
 */
int get_swState (int dipVal){
	volatile unsigned int swState;

	MICO_GPIO_READ_DATA(gpio_ctx, swState);
	return swState & (unsigned int)dipVal;
}

/*
 *
	Waits until specified dip_switch is turned ON
 */
int wait_on_sw (unsigned int dipVal){

	volatile unsigned int swState;

	while (!(swState & dipVal)){
		MICO_GPIO_READ_DATA(gpio_ctx, swState);
	}
	return 0;
}

