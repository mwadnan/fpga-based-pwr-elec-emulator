`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 	IFA, ETHZ
// Engineer: 	MWA
// 
// Create Date:    13:57:43 04/15/2013 
// Design Name: 
// Module Name:    mcb_wrapper 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mcb_wrapper(
		// Infrastructure interface
    input SYS_CLK,
    input RST,
	 output CALIB_DONE,
		// user interface
	 input USER_CLK,
			// CMD
			input CMD_EN,
			input [2:0]	CMD_INSTR,
			input [5:0]	CMD_BURST_LENGTH, 
			input [29:0] CMD_ADDR,
			output CMD_FULL,
			output CMD_EMPTY,
			// WRITE
			input WR_EN,
			input [3:0] WR_MASK,
			input [31:0] WR_DATA,
			output WR_FULL,
			output WR_EMPTY,
			output WR_UNDERRUN,
			output WR_ERROR,
			output [6:0] WR_FIFO_COUNT,
			// READ
			input RD_EN,
			output [31:0] RD_DATA,
			output RD_FULL,
			output RD_EMPTY,
			output RD_OVERFLOW,
			output RD_ERROR,
			output [6:0] RD_FIFO_COUNT,
		// external interface
	 inout [15:0] DRAM_DQ,
	 inout DRAM_DQS,
	 inout DRAM_UDQS,
	 inout DRAM_RZQ,
	 output [12:0] DRAM_A,
	 output [1:0] DRAM_BA,
	 output DRAM_CKE,
	 output DRAM_RAS_N,
	 output DRAM_CAS_N,
	 output DRAM_WE_N,
	 output DRAM_DM,
	 output DRAM_UDM,
	 output DRAM_CLK,
	 output DRAM_CLK_N
    );

	mcb_bank3 # (
		 .C3_P0_MASK_SIZE(4),
		 .C3_P0_DATA_PORT_SIZE(32),
		 .C3_P1_MASK_SIZE(4),
		 .C3_P1_DATA_PORT_SIZE(32),
		 .DEBUG_EN(0),
		 .C3_MEMCLK_PERIOD(6000),
		 .C3_CALIB_SOFT_IP("TRUE"),
		 .C3_SIMULATION("FALSE"),
		 .C3_RST_ACT_LOW(0),
		 .C3_INPUT_CLK_TYPE("NO_IBUF"),
		 .C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
		 .C3_NUM_DQ_PINS(16),
		 .C3_MEM_ADDR_WIDTH(13),
		 .C3_MEM_BANKADDR_WIDTH(2)
	)
	inst_mcb (

		  .c3_sys_clk           (SYS_CLK),
	  .c3_sys_rst_n           (RST),                        

	  .mcb3_dram_dq           (DRAM_DQ),  
	  .mcb3_dram_a            (DRAM_A),  
	  .mcb3_dram_ba           (DRAM_BA),
	  .mcb3_dram_ras_n        (DRAM_RAS_N),                        
	  .mcb3_dram_cas_n        (DRAM_CAS_N),                        
	  .mcb3_dram_we_n         (DRAM_WE_N),                          
	  .mcb3_dram_cke          (DRAM_CKE),                          
	  .mcb3_dram_ck           (DRAM_CLK),                          
	  .mcb3_dram_ck_n         (DRAM_CLK_N),       
	  .mcb3_dram_dqs          (DRAM_DQS),
	  .mcb3_dram_udqs         (DRAM_UDQS),    // for X16 parts
	  .mcb3_dram_udm          (DRAM_UDM),     // for X16 parts
	  .mcb3_dram_dm           (DRAM_DM),

	  .c3_clk0		        (),
	  .c3_rst0		        (),
		
	 
	  .c3_calib_done    (CALIB_DONE),
	  
	  .mcb3_rzq               (DRAM_RZQ),
			  
		  .c3_p0_cmd_clk                          (USER_CLK),
		.c3_p0_cmd_en                           (CMD_EN),
		.c3_p0_cmd_instr                        (CMD_INSTR),
		.c3_p0_cmd_bl                           (CMD_BURST_LENGTH),
		.c3_p0_cmd_byte_addr                    (CMD_ADDR),
		.c3_p0_cmd_empty                        (CMD_EMPTY),
		.c3_p0_cmd_full                         (CMD_FULL),
		.c3_p0_wr_clk                           (USER_CLK),
		.c3_p0_wr_en                            (WR_EN),
		.c3_p0_wr_mask                          (WR_MASK),
		.c3_p0_wr_data                          (WR_DATA),
		.c3_p0_wr_full                          (WR_FULL),
		.c3_p0_wr_empty                         (WR_EMPTY),
		.c3_p0_wr_count                         (WR_FIFO_COUNT),
		.c3_p0_wr_underrun                      (WR_UNDERRUN),
		.c3_p0_wr_error                         (WR_ERROR),
		.c3_p0_rd_clk                           (USER_CLK),
		.c3_p0_rd_en                            (RD_EN),
		.c3_p0_rd_data                          (RD_DATA),
		.c3_p0_rd_full                          (RD_FULL),
		.c3_p0_rd_empty                         (RD_EMPTY),
		.c3_p0_rd_count                         (RD_FIFO_COUNT),
		.c3_p0_rd_overflow                      (RD_OVERFLOW),
		.c3_p0_rd_error                         (RD_ERROR)
	);

endmodule
