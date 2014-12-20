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
#define ADC_INTERFACE_BASEADDR		0x00002000
#define PWM_GEN_BASEADDR			0x00004000

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
 *  ADC_INTERFACE
 */
#define ADC_CONTROL					(ADC_INTERFACE_BASEADDR + 0x000)
#define ADC_STATUS					(ADC_INTERFACE_BASEADDR + 0x000)

#define ADC_SAMPLE_BASEADDR			(ADC_INTERFACE_BASEADDR + 0x000)
#define ADC_N_SAMPLES 				4

/*
 *  PWM Generator
 */
#define PWM_CONTROL					(PWM_GEN_BASEADDR + 0x000)
#define PWM_STATUS					(PWM_GEN_BASEADDR + 0x000)

#define PWM_REF_BASEADDR			(PWM_GEN_BASEADDR + 0x004)
#define PWM_N_REF 					3

/**************************************************************************
 *  Bit Addressing
 *************************************************************************/
/*
 *  DDR_CTRL
 */
#define DDR_CONTROL_DUMP_EN				0x00000001
#define DDR_CONTROL_SOFT_RST			0x00000002
#define DDR_CONTROL_INIT_READ			0x00000004
#define DDR_CONTROL_PERIOD_MASK			0x00000FFF			//12 bits
#define DDR_CONTROL_PERIOD_SHIFT		3					//Shift defined from LSB

#define DDR_STATUS_DDR_RDY				0x00000001
#define DDR_STATUS_RD_DONE				0x00000002
#define DDR_STATUS_DDR_ERROR			0x00000004
#define DDR_STATUS_BURST_CNT_MASK		0x0003FFFF			//18 bits
#define DDR_STATUS_BURST_CNT_SHIFT		3					//Shift defined from LSB

/*
 *  ADC_INTERFACE
 */
#define ADC_EN							0x00000001
#define ADC_SPI_CLKDIV_MASK				0x000000FF			//8 bits
#define ADC_SPI_CLKDIV_SHIFT			1					//Shift defined from LSB

/*
 *  PWM GENERATOR
 */
#define PWM_INTR_EN						0x00000001
#define PWM_SW_EN_1						0x00000002
#define PWM_SW_EN_2						0x00000004
#define PWM_SW_EN_3						0x00000008
#define PWM_PERIOD_MASK					0x0000FFFF			//16 bits
#define PWM_PERIOD_SHIFT				4					//Shift defined from LSB

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
