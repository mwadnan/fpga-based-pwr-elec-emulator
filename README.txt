Last Backup Date: 13/01/2014

Backup of Firmware and Software code and Documentation for Project: 
Emulator/Controller for Switched Power Electronic Systems

Code Organization:
	* Seperate folders for files corresponding to Xilinx ISE and Lattice MicoSystem IDE
	* Common HDL/IPCORE files stored in folder ise/src
	* Project files specific to emulator and controller firmware/software organized in seperate folders
	* Documentation includes address mappings and a document explaining integrating Lattice LM32 cpu core with Xilinx ISE

Current Functionality:
	System
		* Parameters correspond to the example of a multiphase DC DC, buck converter
		* given system runs at 8.33MHz
		* PWM switch frequency is 40KHz

	Firmware:
		* LM32 CPU with a Wishbone Bus based fabric
			* CPU Peripherals - GPIO (4in, 4out) and UART
			* CPU uses Inline Block Memory for instructions and data (for faster memory access)
			* Includes a BMM file for mapping contents of Instruction and Data memory to the block RAM primitives.
			* Code to exclude CPU from synthesis (for analysis of custom logic blocks)
		* WISHBONE Slave interface
			* Support for generic number of slaves, with generic number of internal registers
			* Clock domain boundary to enable separate clocks for CPU and rest of firmware blocks
		* DDR_CTRL state machine to dump and retrieve data from DDR memory
			* Slave interface for control information from CPU
			* Data Frames are written to DDR memory periodically (specified by PERIOD on CONTROL) 
			* Write data fed using a sequencer
			* State machine to generate the read/write requests
			* DDR (MCB) controller 
		* State Update Module 
			* Timing verified in behavioral simulation 
			* Fixed point arithmetic incorporated
			* Verified on HW
			* 18 bit arithmetic incorporated
		* ADC Emulator with SPI Slave (Emulator Only)
		* ADC Interface with SPI Master (Controller Only)
		* PWM Generator 
			* Takes Duty cycle information from CPU
			* no phase offset
		* PWM Generator v2
			* Takes thresholds for rise and fall instances from CPU
			* allows phase offset 
			* optimized to run upto 200 MHz
		* PWM Filter
			* Moving average filter for input PWM signals
			* Takes care of clock drift between controller and emulator board
			* software programmable order of filter (size of moving window)
					
	Software:
		* Header files for Wishbone Slave interface - quickest possible peripheral access
		* Code to test out DDR_CTRL
		* Code for Initializing coefficients for State Update 
			* The initialization vectors are generated using MATLAB script
		* Controller: ISR to 
			* Phase shifted PWM - Generates ON-time and OFF time
		
	



