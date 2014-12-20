/* 
 * emu_parameter.h 
 * 
 * 	 Created on: 27-Sep-2013 
 * 	 Author: adnanm 
 */ 

#ifndef EMU_PARAMETER_H_ 
 #define EMU_PARAMETER_H_ 

/* 
 * 	 SOFTWARE PARAMETERS 
 */ 

#define S1_COEFF_MEM_SIZE 		 68 

#define S1_UPDATE_PERIOD 		 10 	 // Fs = 4.167e+006; Fclk = 1.667e+008/4 

/* 
 * 	 Arrays containing Coefficients for State Update 
 * 	 The arrays are stored in separate C files, that are generated using a MATLAB script 
 */ 

extern short S1_CoeffMemData [];

#endif /* EMU_PARAMETER_H_ */ 
