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
#define DDR_FRAME_SIZE					7
#define DUMP_PERIOD						3125			// ~= (PERIOD(in sec)*166.67e6/8) => PERIOD = 150us
#define CPU_CALC_PERIOD					2083			// ~= (PERIOD(in sec)*166.67e6/8) => PERIOD = 100us

#define UDC_VAL 						0xABCD

// Function Prototypes
void FWBlocksISR (unsigned int, void*);

void coeff_mem_write (volatile int* BaseAddress, short CoeffData[], int Length);

int main() {

	volatile int* ddrControl;
	volatile int* ddrStatus;
	volatile int* ddrRdAddr;
	volatile int* ddrRdData;

	volatile int* ADCControl;

	volatile int* S1_Control;
	volatile int* S1_CoeffMemPtr;

	volatile int* S2_Control;
	volatile int* S2_CoeffMemPtr;

	volatile int* CPUCalcControl;

	int ddrBurstCount;

	int i, j;

	/*
	 *  Software Initialization
	 */
	init_user_interface ();

	SET_POINTER(ddrControl, DDR_CTRL_CONTROL);
	SET_POINTER(ddrStatus, DDR_CTRL_STATUS);
	SET_POINTER(ddrRdAddr, DDR_CTRL_RD_ADDR);
	SET_POINTER(ddrRdData, DDR_CTRL_FIFO_DATA);

	SET_POINTER(ADCControl, ADC_CONTROL);

	SET_POINTER(S1_Control, S1_CONTROL);
	SET_POINTER(S1_CoeffMemPtr, S1_COEFF_BASEADDR);

	SET_POINTER(S2_Control, S2_CONTROL);
	SET_POINTER(S2_CoeffMemPtr, S2_COEFF_BASEADDR);

	SET_POINTER(CPUCalcControl, CALC_CONTROL);

	/*
	 * 		Initialize all Control Registers
	 */
	*ddrControl = 0;
	*CPUCalcControl = 0;
	*S1_Control = 0;
	*S2_Control = 0;

	*ADCControl = (volatile int) UDC_VAL;

	wait_on_sw(DIP_2);

	/*
	 *  Initialize DDR Controller
	 *  	- Wait until MCB is calibrated
	 */
	*ddrControl = DDR_CONTROL_SOFT_RST;

	while(!(*ddrStatus & DDR_STATUS_DDR_RDY));

	/*
	 *  Initialization of Coefficients for State Update Modules
	 */
	coeff_mem_write(S1_CoeffMemPtr, S1_CoeffMemData, S1_COEFF_MEM_SIZE);

	coeff_mem_write(S2_CoeffMemPtr, S2_CoeffMemData, S2_COEFF_MEM_SIZE);

	/*
	 *  Enable the Interrupt from CPU_CALC block
	 *  Register the corresponding ISR
	 */
	MicoRegisterISR(1, (void *)CPUCalcControl, FWBlocksISR);
	MicoEnableInterrupt(1);

	/*
	 *  Enable Firmware blocks
	 *  	Enable State Update Blocks (S1 and S2)
	 *  	Enable Interrupt generation from CPU_CALC block
	 *  	Enable Data Dump to DDR memory
	 */
	*S1_Control = ((S1_UPDATE_PERIOD & S_CONTROL_PERIOD_MASK)<<S_CONTROL_PERIOD_SHIFT) |
					S_CONTROL_UPDATE_EN;

	*CPUCalcControl = ((CPU_CALC_PERIOD & CALC_CONTROL_PERIOD_MASK)<<CALC_CONTROL_PERIOD_SHIFT) |
						CALC_CONTROL_INTR_EN;

	*S2_Control = ((S2_UPDATE_PERIOD & S_CONTROL_PERIOD_MASK)<<S_CONTROL_PERIOD_SHIFT) |
					S_CONTROL_UPDATE_EN;

	*ddrControl = ((DUMP_PERIOD & DDR_CONTROL_PERIOD_MASK)<<DDR_CONTROL_PERIOD_SHIFT) |
					DDR_CONTROL_DUMP_EN;


	/*
	 *  CPU IDLE Mode
	 */
	MicoSleepMilliSecs(400);

	wait_on_sw(DIP_2);

	/*
	 *  Disable the Interrupt from CPU_CALC block
	 */
	MicoDisableInterrupt(1);

	/*
	 *  Disable Calculations, Data Dump
	 */
	*S1_Control = 0;
	*CPUCalcControl = 0;
	*S2_Control = 0;
	*ddrControl = 0;

	/*
	 *  Read Data from DDR Memory
	 */
	ddrBurstCount = (*ddrStatus >> DDR_STATUS_BURST_CNT_SHIFT) & DDR_STATUS_BURST_CNT_MASK;
	printf("%d\n", ddrBurstCount);

	for (i=0; i<ddrBurstCount; i++){
		for (j=0; j<DDR_FRAME_SIZE; j++){
			*ddrRdAddr  = (i*DDR_FRAME_SIZE + j)*4;
			*ddrControl = DDR_CONTROL_INIT_READ;

			while (!(*ddrStatus & DDR_STATUS_RD_DONE));

			*ddrControl = 0;
			printf("%d ", (int)*ddrRdData);
		}
		printf("\n");
	}

	set_LED(LED_1);
	while (1){

	}

	return 0;

}

/*
 *  Interrupt Service Routine for Interrupts generated from Firmware blocks via Wishbone Slave Interface
 *  There is only one interrupt (corresponding to CPU_CALC),
 *  The argument pData is a pointer to the CPU_CALC_CONTROL
 */
void FWBlocksISR (unsigned int intLevel, void* pData){

	volatile int* CalcRegs;

	volatile int rdVal;
	int wrVal;

	short IStatorAlpha, IStatorBeta;
	short PsiAlpha, PsiBeta;
	short Omega;

	int Torque;

	CalcRegs = (volatile int*)pData;

	rdVal = *(CalcRegs+1);
	IStatorAlpha = (short)(rdVal & 0xFFFF);
	IStatorBeta = (short)((rdVal>>16) & 0xFFFF);
	rdVal = *(CalcRegs+2);
	PsiAlpha = (short)(rdVal & 0xFFFF);
	PsiBeta = (short)((rdVal>>16) & 0xFFFF);
	rdVal = *(CalcRegs+3);
	Omega = (short)(rdVal & 0xFFFF);

	// Computing Absolute of Omega
	if (Omega < 0)
		Omega = -Omega;

	// Computing Torque = PsiAlpha*IStatorBeta - PsiBeta*IStatorAlpha
	Torque = ((int)PsiAlpha * (int)IStatorBeta) - ((int)PsiBeta * (int)IStatorAlpha);
	Torque = Torque<<1;

	// Writing Outputs
	wrVal = ((int)Omega << 16) | ((Torque & 0xFFFF0000) >> 16);
	*(CalcRegs+1) = (volatile int) wrVal;

	return;
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
