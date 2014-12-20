/* 
 * emu_parameter.h 
 * 
 * 	 Created on: 11-Sep-2013 
 * 	 Author: adnanm 
 */ 

#ifndef EMU_PARAMETER_H_ 
 #define EMU_PARAMETER_H_ 

/* 
 * 	 SOFTWARE PARAMETERS 
 */ 

#define S1_COEFF_MEM_SIZE 		 64 

#define S2_COEFF_MEM_SIZE 		 16 

#define S1_UPDATE_PERIOD 		 208 	 // Fs = 1.000e+005; Fclk = 1.667e+008/8 

#define S2_UPDATE_PERIOD 		 2083 	 // Fs = 1.000e+004; Fclk = 1.667e+008/8 

/* 
 * 	 Arrays containing Coefficients for State Update 
 * 	 The arrays are stored in separate C files, that are generated using a MATLAB script 
 */ 

extern short S1_CoeffMemData [];
extern short S2_CoeffMemData [];

#endif /* EMU_PARAMETER_H_ */ 
