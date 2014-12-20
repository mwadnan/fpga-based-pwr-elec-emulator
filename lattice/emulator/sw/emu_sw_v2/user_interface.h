/*
 * user_interface.h
 *
 *  Created on: 06.05.2013
 *      Author: Wasif
 */

#ifndef USER_INTERFACE_H_
#define USER_INTERFACE_H_

#include "MicoUtils.h"
#include "MicoGPIO.h"

// Dip Switch Inputs
#define DIP_1	0x01000000
#define DIP_2	0x02000000
#define DIP_3	0x04000000
#define DIP_4	0x08000000

// LED Outputs
#define LED_1	0x01000000
#define LED_2	0x02000000
#define LED_3	0x04000000
#define LED_4	0x08000000

// Context Pointer
extern MicoGPIOCtx_t* gpio_ctx;

// Function Prototypes
void init_user_interface ();

int set_LED (int ledVal);

int get_swState (int dipVal);		//return 1 if specified dip_switch is turned ON

int wait_on_sw (unsigned int dipVal);		//Wait until specified dip_switch is turned ON

#endif /* USER_INTERFACE_H_ */
