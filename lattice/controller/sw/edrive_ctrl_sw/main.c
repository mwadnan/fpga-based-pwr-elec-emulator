/*
 * main.c
 *
 *  Created on: 25.04.2013
 *      Author: adnanm
 */
#include <stdio.h>

#include "MicoInterrupts.h"
#include "MicoUtils.h"

#include "firmware_interface.h"
#include "user_interface.h"

#include "ctrl_parameter.h"

// Parameter Macros
#define DDR_FRAME_SIZE					5
#define DUMP_PERIOD						167				// ~= (PERIOD(in sec)*66e6/4) => PERIOD = 10us

#define ADC_CLKDIV_PERIOD				16				// SPI_CLK ~= 515.6KHz

// Function Prototypes
void FWBlocksISR (unsigned int, void*);

// Global Variables
int SwCycles = 0;
int RefIndex = 0;
int DRef = 0;

int main() {

	volatile int* ddrControl;
	volatile int* ddrStatus;
	volatile int* ddrRdAddr;
	volatile int* ddrRdData;

	volatile int* ADCControl;
	volatile int* ADCSample;

	volatile int* PWMControl;
	volatile int* PWMRef;

	/*
	 *  Software Initialization
	 */
	init_user_interface ();

	SET_POINTER(ddrControl, DDR_CTRL_CONTROL);
	SET_POINTER(ddrStatus, DDR_CTRL_STATUS);
	SET_POINTER(ddrRdAddr, DDR_CTRL_RD_ADDR);
	SET_POINTER(ddrRdData, DDR_CTRL_FIFO_DATA);

	SET_POINTER(ADCControl, ADC_CONTROL);
	SET_POINTER(ADCSample, ADC_SAMPLE_BASEADDR);

	SET_POINTER(PWMControl, PWM_CONTROL);
	SET_POINTER(PWMRef, PWM_REF_BASEADDR);

	/*
	 * 		Initialize all Control Registers
	 */
	*ddrControl = 0;
	*ADCControl = 0;
	*PWMControl = 0;

	/*
	 *  Initialize DDR Controller
	 *  	- Wait until MCB is calibrated
	 */
	*ddrControl = DDR_CONTROL_SOFT_RST;

	while(!(*ddrStatus & DDR_STATUS_DDR_RDY));

	/*
	 *  Enable the Interrupt from FW blocks
	 *  Register the corresponding ISR
	 */
	MicoRegisterISR(1, (void *)PWMRef, FWBlocksISR);
	MicoEnableInterrupt(1);

	/*
	 *  Enable Firmware blocks
	 *  	Enable ADC Interface (SPI Master)
	 *  	Enable PWM Generator block
	 */
	*PWMControl = ((PWM_PERIOD & PWM_PERIOD_MASK)<<PWM_PERIOD_SHIFT) |
						PWM_INTR_EN |
						PWM_SW_EN_1 |
						PWM_SW_EN_2 |
						PWM_SW_EN_3;

	*ADCControl = ((ADC_CLKDIV_PERIOD & ADC_SPI_CLKDIV_MASK)<<ADC_SPI_CLKDIV_SHIFT) |
						ADC_EN;


	while (1){
	/*
	 *  CPU IDLE Mode
	 */
	MicoSleepMilliSecs(1000);

	set_LED(LED_1);

	MicoSleepMilliSecs(1000);

	set_LED(LED_2);

	}

	/*
	 *  Disable the Interrupt from PWM GEN block
	 */
	MicoDisableInterrupt(1);

	return 0;
}

/*
 *  Interrupt Service Routine for Interrupts generated from Firmware blocks via Wishbone Slave Interface
 *  There is only one interrupt (corresponding to PWM_GEN),
 *  The argument pData is a pointer to the PWM_REF_BASEADDR
 *
 *  The ISR computes new reference points for the PWM_GEN and loads them for the next period
 */
void FWBlocksISR (unsigned int intLevel, void* pData){

	volatile int* PWMRef;
	unsigned int wrVal;

	int DutyCycle;
	unsigned short OffTime[3];

	int i;

	PWMRef = (volatile int*)pData;

	// Increment phase values
	SwCycles++;
	if (SwCycles >= 400){
		SwCycles = 0;
		RefIndex++;
		if (RefIndex >= 2)
			RefIndex = 0;
	}

	/*
	 *  LowPass filter for Duty Cycle
	 */
	DRef = ((int)FiltCoeff[0] * (DRef>>16)) + ((int)FiltCoeff[1] * (int)VoltageRef[RefIndex]);
	DRef = DRef<<1;

	/*
	 *  Normalize Ref w.r.t. Period to obtain duty cycle
	 */
	//DutyCycle = ((int)PWM_PERIOD * (DRef>>16));
	DutyCycle = ((int)PWM_PERIOD * (int)VoltageRef[RefIndex]);
	DutyCycle = DutyCycle<<1;

	/*
	 *  Compute OffTime
	 *  Writing References to PWM_GEN block
	 */
	for (i=0; i<3; i++){
		OffTime[i] = PhaseOffset[i] + (unsigned short)((DutyCycle & 0xFFFF0000) >> 16);
		if (OffTime[i] > (unsigned short)PWM_PERIOD)
			OffTime[i] = OffTime[i] - (unsigned short)PWM_PERIOD;

		wrVal = (OffTime[i]<<16) | PhaseOffset[i];
		*(PWMRef+i) = (volatile int) wrVal;
	}

	return;
}
