/*
 * firmware_interface.h
 *
 *  Created on: 25.04.2013
 *      Author: Wasif
 */

#ifndef FIRMWARE_INTERFACE_H_
#define FIRMWARE_INTERFACE_H_

#define WB_SLAVE_BASEADDR			0x80000000

/**************************************************************************
 *  Block Base Addresses
 *************************************************************************/
#define DDR_CTRL_BASEADDR 			0x00001000
#define ADC_EMULATOR_BASEADDR		0x00002000
#define CPU_CALC_BASEADDR			0x00004000
#define PWM_FILT_BASEADDR			0x00008000
#define STATE_UPDATE_S1_BASEADDR	0x00010000

/**************************************************************************
 *  Block Register Addresses
 *************************************************************************/
/*
 *  DDR_CTRL
 */
#define DDR_CTRL_CONTROL			(DDR_CTRL_BASEADDR + 0x000)
#define DDR_CTRL_STATUS				(DDR_CTRL_BASEADDR + 0x000)
#define DDR_CTRL_RD_ADDR			(DDR_CTRL_BASEADDR + 0x004)
#define DDR_CTRL_FIFO_DATA			(DDR_CTRL_BASEADDR + 0x004)

/*
 *  ADC_EMULATOR
 */
#define ADC_CONTROL					(ADC_EMULATOR_BASEADDR + 0x000)
#define ADC_STATUS					(ADC_EMULATOR_BASEADDR + 0x000)

/*
 *  CPU_CALC
 */
#define CALC_CONTROL				(CPU_CALC_BASEADDR + 0x000)
#define CALC_STATUS					(CPU_CALC_BASEADDR + 0x000)

/*
 *  PWM_FILTER
 */
#define PWM_FILT_CONTROL			(PWM_FILT_BASEADDR + 0x000)
#define PWM_FILT_STATUS				(PWM_FILT_BASEADDR + 0x000)

/*
 *  STATE_UPDATE_S1
 */
#define S1_CONTROL					(STATE_UPDATE_S1_BASEADDR + 0x400)
#define S1_STATUS					(STATE_UPDATE_S1_BASEADDR + 0x400)
#define S1_COEFF_BASEADDR			(STATE_UPDATE_S1_BASEADDR + 0x000)

/**************************************************************************
 *  Bit Addressing
 *************************************************************************/
/*
 *  DDR_CTRL CONTROL
 */
#define DDR_CONTROL_DUMP_EN					0x00000001
#define DDR_CONTROL_SOFT_RST				0x00000002
#define DDR_CONTROL_INIT_READ				0x00000004
#define DDR_CONTROL_PERIOD_MASK				0x00000FFF			//12 bits
#define DDR_CONTROL_PERIOD_SHIFT			3					//Shift defined from LSB

#define DDR_STATUS_DDR_RDY					0x00000001
#define DDR_STATUS_RD_DONE					0x00000002
#define DDR_STATUS_DDR_ERROR				0x00000004
#define DDR_STATUS_BURST_CNT_MASK			0x0003FFFF			//18 bits
#define DDR_STATUS_BURST_CNT_SHIFT			3					//Shift defined from LSB

/*
 *  CPU_CALC CONTROL
 */
#define CALC_CONTROL_INTR_EN				0x00000001
#define CALC_CONTROL_PERIOD_MASK			0x00000FFF			//12 bits
#define CALC_CONTROL_PERIOD_SHIFT			1

/*
 *  PWM_FILTER CONTROL
 */
#define FILT_CONTROL_INPUT_EN				0x00000001
#define FILT_CONTROL_COEFF_MASK				0x0000FFFF			//16 bits
#define FILT_CONTROL_COEFF_SHIFT			1

/*
 *  STATE_UPDATE CONTROL
 */
#define S_CONTROL_SOFT_RST					0x00000001
#define S_CONTROL_UPDATE_EN					0x00000002
#define S_CONTROL_PERIOD_MASK				0x00000FFF			//12 bits
#define S_CONTROL_PERIOD_SHIFT				2					//Shift defined from LSB

#define S_STATUS_CALC_ERROR					0x00000001

/*************************************************************************
 * Master Operations on the WISHBONE Bus
 ************************************************************************/
	/*
	 * Set the address of a Pointer to a Slave Block
	 * 		ADDRESS - Valid address (Look at Macros above)
	 * 		PTR - 	  volatile int * type variable
	 */
	#define SET_POINTER(PTR, ADDRESS) \
				(PTR) = ((volatile int*)(WB_SLAVE_BASEADDR + ADDRESS))

	/*
	 * 	Read Slave Block
	 * 		ADDRESS - Valid address (Verify R/W permissions for the specified Block)
	 * 		Data - volatile int type variable
	 */
	#define SLAVE_READ(ADDRESS, DATA) \
				(DATA) = *((volatile int*)(WB_SLAVE_BASEADDR + ADDRESS))

	/*
	 * 	Write to Slave Block
	 * 		ADDRESS - Valid address (Verify R/W permissions for the specified Block)
	 * 		Data - volatile int type variable
	 */
	#define SLAVE_WRITE(ADDRESS, DATA) \
				*((volatile int*)(WB_SLAVE_BASEADDR + ADDRESS)) = (volatile int)DATA


#endif /* FIRMWARE_INTERFACE_H_ */
