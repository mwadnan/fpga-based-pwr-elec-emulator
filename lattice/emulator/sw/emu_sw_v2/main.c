/*
 * main.c
 *
 *  Created on: 25.04.2013
 *      Author: adnanm
 */
#include <stdio.h>

#include "MicoInterrupts.h"
#include "MicoUtils.h"

#include "emu_parameter.h"
#include "firmware_interface.h"
#include "user_interface.h"

// Parameter Macros
#define DDR_FRAME_SIZE					5
#define DUMP_PERIOD						50				// ~= (PERIOD(in sec)*166.67e6/4) => PERIOD = 1.2us
#define CPU_CALC_PERIOD					10				// ~= (PERIOD(in sec)*166.67e6/4) => PERIOD = 240ns

#define PWM_FILT_COEFF					1573			//	U_DC/(UPDATE_PERIOD*25)*(2^15) => Vdc = 24V, UPDATE_PERIOD = 5*4

#define R_L_INV 						6553			//	(1/R_L)*(2^15) => R_L = 5 Ohms
#define I_L_VAL 						0			//	Current/10*(2^15)) => i_L = 0A

// Function Prototypes
void coeff_mem_write (volatile int* BaseAddress, short CoeffData[], int Length);

int main() {

	volatile int* ddrControl;
	volatile int* ddrStatus;
	volatile int* ddrRdAddr;
	volatile int* ddrRdData;

	volatile int* CPUCalcControl;

	volatile int* PWMFiltControl;

	volatile int* S1_Control;
	volatile int* S1_CoeffMemPtr;

	int ddrBurstCount;
	int frameID;
	int rdData;
	int rdAddr;

	int i, j;
	int toggle;

	int k;
	/*
	 *  Software Initialization
	 */
	init_user_interface ();
	MicoSleepMilliSecs(2000);

	set_LED(LED_1 | LED_2);


	SET_POINTER(ddrControl, DDR_CTRL_CONTROL);
	SET_POINTER(ddrStatus, DDR_CTRL_STATUS);
	SET_POINTER(ddrRdAddr, DDR_CTRL_RD_ADDR);
	SET_POINTER(ddrRdData, DDR_CTRL_FIFO_DATA);

	SET_POINTER(CPUCalcControl, CALC_CONTROL);
	SET_POINTER(PWMFiltControl, PWM_FILT_CONTROL);

	SET_POINTER(S1_Control, S1_CONTROL);
	SET_POINTER(S1_CoeffMemPtr, S1_COEFF_BASEADDR);

	/*
	 * 		Initialize all Control Registers
	 */
	*ddrControl = 0;
	*S1_Control = 0;
	*CPUCalcControl = 0;
	*PWMFiltControl = 0;

	/*
	 *  Initialize DDR Controller
	 *  	- Wait until MCB is calibrated
	 */
	*ddrControl = DDR_CONTROL_SOFT_RST;

	while(!(*ddrStatus & DDR_STATUS_DDR_RDY));

	/*
	 *  Initialization of Coefficients for State Update Modules
	 */
	*PWMFiltControl = ((PWM_FILT_COEFF & FILT_CONTROL_COEFF_MASK)<<FILT_CONTROL_COEFF_SHIFT) |
							FILT_CONTROL_INPUT_EN;
	*CPUCalcControl = ((CPU_CALC_PERIOD & CALC_CONTROL_PERIOD_MASK)<<CALC_CONTROL_PERIOD_SHIFT) |
							CALC_CONTROL_INTR_EN;
	*(CPUCalcControl+1) = ((int)I_L_VAL << 16) | ((int)R_L_INV & 0xFFFF);
	coeff_mem_write(S1_CoeffMemPtr, S1_CoeffMemData, S1_COEFF_MEM_SIZE);

	/*
	 *  Enable the Interrupt from CPU_CALC block
	 *  Register the corresponding ISR
	 */
	//MicoRegisterISR(1, (void *)CPUCalcControl, FWBlocksISR);
	//MicoEnableInterrupt(1);
	/*
	 *  Disable the Interrupt from CPU_CALC block
	 */
	//MicoDisableInterrupt(1);

	/*
	 *  Enable Firmware blocks
	 *  	Enable State Update Blocks (S1)
	 */
	*S1_Control = ((S1_UPDATE_PERIOD & S_CONTROL_PERIOD_MASK)<<S_CONTROL_PERIOD_SHIFT) |
					S_CONTROL_UPDATE_EN;

	/*
	 *  Repeated Operation
	 *  	Dump state in Memory for some time
	 *  	Read Memory contents and send on UART
	 *  	Reset and dump again...
	 *
	 */
	toggle = 0;
	while (1){

		*ddrControl = ((DUMP_PERIOD & DDR_CONTROL_PERIOD_MASK)<<DDR_CONTROL_PERIOD_SHIFT) |
						DDR_CONTROL_DUMP_EN;

		/*
		 *  CPU IDLE Mode
		 */
		MicoSleepMilliSecs(20);

		/*
		 *  Disable Data Dump
		 */
		if (*ddrStatus & DDR_STATUS_DDR_ERROR){
			*ddrControl = DDR_CONTROL_SOFT_RST;
			printf("E!");
			continue;
		}
		else{
			*ddrControl = 0;				//disable Data Dump
			printf("S\n");
		}

		/*
		 *  Read Data from DDR Memory
		 */
		ddrBurstCount = ((*ddrStatus >> DDR_STATUS_BURST_CNT_SHIFT) & DDR_STATUS_BURST_CNT_MASK)-5;
		printf("%d\n", ddrBurstCount);

		rdAddr = 0;
		for (i=0; i<ddrBurstCount; i++){
			do{
				*ddrRdAddr  = rdAddr;
				*ddrControl = DDR_CONTROL_INIT_READ;

				while (!(*ddrStatus & DDR_STATUS_RD_DONE));

				*ddrControl = 0;
				frameID = (int)*ddrRdData;
				rdAddr+=4;
			}while (frameID != i);
			printf("%d ", frameID);

			for (j=1; j<DDR_FRAME_SIZE; j++){
				*ddrRdAddr  = rdAddr;
				*ddrControl = DDR_CONTROL_INIT_READ;

				while (!(*ddrStatus & DDR_STATUS_RD_DONE));

				*ddrControl = 0;
				rdData = (int)*ddrRdData;
				printf("%d ", rdData);
				rdAddr+=4;
			}
			printf("\n");
		}

		*ddrControl = DDR_CONTROL_SOFT_RST;			//Reset write addresses

		if (toggle == 0){
			set_LED(LED_1);
			toggle = 1;
		}
		else{
			set_LED(0);
			toggle = 0;
		}

	}

	return 0;

}

/*
 * 	 Writes the array of (type Short (16-bit)) Data to the Base Address given as input
 * 	 Each Write operation is a 32-bit data write
 */
void coeff_mem_write (volatile int* BaseAddress, short CoeffData[], int Length){
	int i, ind;

	int writeData;

	if (Length == 1){
		writeData = ((int)CoeffData[0] & 0xFFFF);
		*BaseAddress = (volatile int)writeData;
	}
	else{
		ind = 0;
		for (i=0; i<Length; i+=2){
			writeData = ((int)CoeffData[i+1] << 16) | ((int)CoeffData[i] & 0xFFFF);
			*(BaseAddress + ind) = (volatile int) writeData;
			ind++;
		}
	}
}
