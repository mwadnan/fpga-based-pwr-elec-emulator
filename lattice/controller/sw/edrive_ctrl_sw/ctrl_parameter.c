/* 
 * ctrl_parameter.c 
 * 
 * 	 Created on: 06-Sep-2013 
 * 	 Author: adnanm 
 */ 

#include "ctrl_parameter.h" 

short VoltageRef[2] = {0x2000, 0x5000};		//6V and 15V

unsigned short PhaseOffset[3] = {0, PWM_PERIOD/3, 2*PWM_PERIOD/3};

short FiltCoeff[2] = {0x799A, 0x0666};

