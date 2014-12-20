/* 
 * ctrl_parameter.h 
 * 
 * 	 Created on: 06-Sep-2013 
 * 	 Author: adnanm 
 */ 

#ifndef CTRL_PARAMETER_H_ 
 #define CTRL_PARAMETER_H_ 

/* 
 * 	 SOFTWARE PARAMETERS 
 */ 

#define PWM_PERIOD 		 	1667 	 // Fs = 4.00e+004; Fclk = 6.600e+007/1

/* 
 * 	 Arrays coefficients/reference vectors 
 * 	 The arrays are stored in separate C files, that are generated using a MATLAB script 
 */ 
extern short VoltageRef[];

extern unsigned short PhaseOffset [];

extern short FiltCoeff [];

#endif /* CTRL_PARAMETER_H_ */ 
