----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    12:22:11 04/26/2013 
-- Design Name: 
-- Module Name:    ddr_ctrl_wrapper - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--					FRAME_SIZE : DDR Controller writes a frame of size (FRAME_SIZE+1).
--					 The extra value corresponds to FRAME_COUNT
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.reduction_op.all;

entity ddr_ctrl_wrapper is
	Generic ( N_SLV_REGS : integer := 2;
				 FRAME_CNT_WIDTH : integer := 18;
				 -- Parameters above are NOT set in a higher hierarchy 
				 FRAME_SIZE  : integer := 10;
				 NUM_WIDTH : integer := 16;
				 FW_ADDR_WIDTH : integer := 8;
				 FW_DATA_WIDTH : integer := 32
				 );
    Port ( CLK 			: in  STD_LOGIC;
           DDR_CLK 		: in  STD_LOGIC;
           RST 			: in  STD_LOGIC;
           EN 				: in  STD_LOGIC;
			  -- WISHBONE Slave Interface 
			  CS				: in  STD_LOGIC;
			  WE				: in  STD_LOGIC;
			  ADDR			: in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
			  DATA_I			: in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  DATA_O			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  -- DATA INPUT for WR_FIFO 
			  WR_DATA_IN 	: in  STD_LOGIC_VECTOR (NUM_WIDTH*FRAME_SIZE-1 downto 0);
			  -- LPDDR Signals
			  DRAM_DQ 		: inout std_logic_vector(15 downto 0);
			  DRAM_DQS 		: inout std_logic;
			  DRAM_UDQS 	: inout std_logic;
			  DRAM_RZQ 		: inout std_logic; 
			  DRAM_A 		: out std_logic_vector(12 downto 0);
			  DRAM_BA 		: out std_logic_vector(1 downto 0);
			  DRAM_CKE 		: out std_logic;
			  DRAM_RAS_N 	: out std_logic;
			  DRAM_CAS_N 	: out std_logic;
			  DRAM_WE_N 	: out std_logic;
			  DRAM_DM 		: out std_logic;
			  DRAM_UDM 		: out std_logic;
			  DRAM_CLK 		: out std_logic;
			  DRAM_CLK_N 	: out std_logic
			 );
end ddr_ctrl_wrapper;

architecture Behavioral of ddr_ctrl_wrapper is

	COMPONENT mcb_wrapper
	PORT(
		SYS_CLK : IN std_logic;
		RST : IN std_logic;
		USER_CLK : IN std_logic;
		CMD_EN : IN std_logic;
		CMD_INSTR : IN std_logic_vector(2 downto 0);
		CMD_BURST_LENGTH : IN std_logic_vector(5 downto 0);
		CMD_ADDR : IN std_logic_vector(29 downto 0);
		WR_EN : IN std_logic;
		WR_MASK : IN std_logic_vector(3 downto 0);
		WR_DATA : IN std_logic_vector(31 downto 0);
		RD_EN : IN std_logic;    
		DRAM_DQ : INOUT std_logic_vector(15 downto 0);
		DRAM_DQS : INOUT std_logic;
		DRAM_UDQS : INOUT std_logic;
		DRAM_RZQ : INOUT std_logic;      
		CALIB_DONE : OUT std_logic;
		CMD_FULL : OUT std_logic;
		CMD_EMPTY : OUT std_logic;
		WR_FULL : OUT std_logic;
		WR_EMPTY : OUT std_logic;
		WR_UNDERRUN : OUT std_logic;
		WR_ERROR : OUT std_logic;
		WR_FIFO_COUNT : OUT std_logic_vector(6 downto 0);
		RD_DATA : OUT std_logic_vector(31 downto 0);
		RD_FULL : OUT std_logic;
		RD_EMPTY : OUT std_logic;
		RD_OVERFLOW : OUT std_logic;
		RD_ERROR : OUT std_logic;
		RD_FIFO_COUNT : OUT std_logic_vector(6 downto 0);
		DRAM_A : OUT std_logic_vector(12 downto 0);
		DRAM_BA : OUT std_logic_vector(1 downto 0);
		DRAM_CKE : OUT std_logic;
		DRAM_RAS_N : OUT std_logic;
		DRAM_CAS_N : OUT std_logic;
		DRAM_WE_N : OUT std_logic;
		DRAM_DM : OUT std_logic;
		DRAM_UDM : OUT std_logic;
		DRAM_CLK : OUT std_logic;
		DRAM_CLK_N : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT block_regs
	GENERIC ( N_SLV_REGS 	: integer;
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer );
	PORT ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           CS : in  STD_LOGIC;
           WE : in  STD_LOGIC;
           ADDR : in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
           WB_DATA_I : in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
           WB_DATA_O : out STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  REG_DATA_I : in STD_LOGIC_VECTOR (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
           REG_DATA_O : out STD_LOGIC_VECTOR (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0)
			);
	END COMPONENT;
	
	COMPONENT trig_gen
	GENERIC ( CNT_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		TRIG_EN : IN std_logic;
		PERIOD : IN std_logic_vector(CNT_WIDTH-1 downto 0);          
		TRIG_OUT : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT reg_serialize
	GENERIC ( N_REGS : integer;
				 NUM_WIDTH : integer );	
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		WE : IN std_logic;
		OE : IN std_logic;
		REG_IN : IN std_logic_vector(N_REGS*NUM_WIDTH-1 downto 0);          
		DOUT : OUT std_logic_vector(NUM_WIDTH-1 downto 0)
		);
	END COMPONENT;
	
	COMPONENT ddr_ctrl_sm
	GENERIC ( FRAME_SIZE : integer;
				 FRAME_CNT_WIDTH : integer );
    PORT ( CLK 				: in  STD_LOGIC;
           RST 				: in  STD_LOGIC;
           EN 					: in  STD_LOGIC;
			  MCB_CALIB_DONE	: in 	STD_LOGIC;
			  WR_TRIG 			: in  STD_LOGIC;
			  SOFT_RST			: in  STD_LOGIC;
			  DUMP_EN 			: in  STD_LOGIC;
			  INIT_READ 		: in  STD_LOGIC;
			  RD_ADDR 			: in  STD_LOGIC_VECTOR (29 downto 0);
			  RD_DONE			: out STD_LOGIC;
			  DDR_RDY			: out STD_LOGIC;
			  DDR_ERROR			: out STD_LOGIC;
			  WR_FIFO_EN		: out STD_LOGIC;
			  FRAME_CNT_O		: out STD_LOGIC_VECTOR (FRAME_CNT_WIDTH-1 downto 0);
			  CMD_FULL			: in  STD_LOGIC;
			  CMD_EMPTY			: in  STD_LOGIC;
			  WR_FULL			: in  STD_LOGIC;
			  WR_EMPTY			: in  STD_LOGIC;
			  WR_UNDERRUN		: in  STD_LOGIC;
			  WR_FIFO_COUNT 	: in  STD_LOGIC_VECTOR(6 downto 0);
			  WR_ERROR			: in  STD_LOGIC;
			  RD_FULL			: in  STD_LOGIC;
			  RD_EMPTY			: in  STD_LOGIC;
			  RD_OVERFLOW		: in  STD_LOGIC;
			  RD_ERROR			: in  STD_LOGIC;
			  RD_FIFO_COUNT 	: in  STD_LOGIC_VECTOR(6 downto 0);
			  CMD_EN				: out  STD_LOGIC;
			  CMD_ADDR 			: out  STD_LOGIC_VECTOR (29 downto 0);
			  CMD_BURST_LENGTH : out  STD_LOGIC_VECTOR (5 downto 0);
			  CMD_INSTR 		: out  STD_LOGIC_VECTOR (2 downto 0)			  
			  );
	END COMPONENT;
	
	signal cmd_en				: std_logic;
	signal cmd_instr			: std_logic_vector(2 downto 0);
	signal cmd_burst_length	: std_logic_vector(5 downto 0);
	signal cmd_addr			: std_logic_vector(29 downto 0);
	signal cmd_full 			: std_logic;
	signal cmd_empty 			: std_logic;
	
	signal wr_en				: std_logic;
	signal wr_mask				: std_logic_vector(3 downto 0);
	signal wr_data				: std_logic_vector(31 downto 0);
	signal wr_full				: std_logic;
	signal wr_empty			: std_logic;
	signal wr_underrun		: std_logic;
	signal wr_error			: std_logic;
	signal wr_fifo_count 	: std_logic_vector (6 downto 0);
	
	signal rd_en				: std_logic;
	signal rd_data				: std_logic_vector(31 downto 0);
	signal rd_full				: std_logic;
	signal rd_empty			: std_logic;
	signal rd_overflow		: std_logic;
	signal rd_error			: std_logic;
	signal rd_fifo_count 	: std_logic_vector (6 downto 0);
	
	signal wr_en_p1			: std_logic;
	
	signal cmd_full_p1 			: std_logic;
	signal cmd_empty_p1 			: std_logic;
	signal wr_full_p1				: std_logic;
	signal wr_empty_p1			: std_logic;
	signal wr_underrun_p1		: std_logic;
	signal wr_error_p1			: std_logic;
	signal rd_full_p1				: std_logic;
	signal rd_empty_p1			: std_logic;
	signal rd_overflow_p1		: std_logic;
	signal rd_error_p1			: std_logic;
	
	signal mcb_calib_done 	: std_logic;
	
	attribute KEEP : string;
	attribute KEEP of mcb_calib_done: signal is "TRUE";
	
	-- Control Register	
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	signal dump_en				: std_logic;
	signal ddr_soft_rst		: std_logic;
	signal init_rd				: std_logic;
	signal wr_trig_period	: std_logic_vector(11 downto 0);
	signal rd_addr 			: std_logic_vector(29 downto 0);
		
	signal ddr_rdy				: std_logic;	
	
	-- FSM Outputs
	signal frame_count		: std_logic_vector(FRAME_CNT_WIDTH-1 downto 0);
	signal rd_done				: std_logic;
	signal ddr_error			: std_logic;
	
	signal wr_fifo_en 		: std_logic;
	
	-- Misc Signals
	signal rd_fifo_pop		: std_logic;
	signal rd_fifo_pop_p1 	: std_logic;
	
	signal wr_trig				: std_logic;
	signal wr_trig_pipe 		: std_logic_vector (FRAME_SIZE+1 downto 0);
	
	signal reg_serial_in		: std_logic_vector((FRAME_SIZE+1)*NUM_WIDTH-1 downto 0);
	
begin
		
-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping in Excel documentation)
	dump_en 							<= reg_data_o(0);
	ddr_soft_rst 					<= reg_data_o(1);
	init_rd 							<= reg_data_o(2);
	wr_trig_period					<= reg_data_o(14 downto 3);
	rd_addr 							<= reg_data_o(61 downto 32);
	
	reg_data_i(0) 					<= ddr_rdy;
	reg_data_i(1) 					<= rd_done;
	reg_data_i(2) 					<= ddr_error;
	reg_data_i(20 downto 3) 	<= frame_count;
	reg_data_i(31 downto 21) 	<= (others => '0');
	reg_data_i(63 downto 32) 	<= rd_data;
			
-- Combinational Logic	
	wr_mask <= (others => '0');	
	DIFF_WIDTHS: if (NUM_WIDTH < 32) generate
		begin
			wr_data(31 downto NUM_WIDTH) <= (31 downto NUM_WIDTH => wr_data(NUM_WIDTH-1));
	end generate;
	
	reg_serial_in <= frame_count(NUM_WIDTH-1 downto 0) & WR_DATA_IN;
	
	process (wr_fifo_en, ddr_rdy, wr_trig_pipe)
	begin
		if ((wr_fifo_en = '1') and (ddr_rdy = '1')) then
			wr_en <= or_reduce(wr_trig_pipe(FRAME_SIZE downto 0));
		else
			wr_en <= '0';
		end if;
	end process;
	 
	-- Signals to POP the RD_FIFO 
	-- (the FIFO should be POPPED once, after read operation is done on the WB bus
	-- Popping FIFO implies that the data value - read last - is discarded. Done using rd_en input to MCB
	rd_en <= rd_fifo_pop_p1 and (not rd_fifo_pop);			-- negative edge	
	
	process (CS, ADDR)
	begin
		if ((CS = '1') and (ADDR(2) = '1') and (WE = '0')) then			-- Address Corresponding to 0x0004
			rd_fifo_pop <= '1';
		else
			rd_fifo_pop <= '0';
		end if;
	end process;
	
-- Synchronous Logic
PIPELINE: process (CLK) 
	begin
		if rising_edge (CLK) then
			rd_fifo_pop_p1 <= rd_fifo_pop;
			wr_trig_pipe <= wr_trig_pipe(FRAME_SIZE downto 0) & wr_trig;
			wr_en_p1 <= wr_en;			
		end if;
	end process;
	
	process (CLK) 
	begin
		if rising_edge (CLK) then
			cmd_full_p1 <= cmd_full;
			cmd_empty_p1 <= cmd_empty;
			wr_full_p1	<= wr_full;
			wr_empty_p1	<= wr_full;
			wr_underrun_p1	<= wr_underrun;
			wr_error_p1	<= wr_error;
			rd_full_p1	<= rd_full;
			rd_empty_p1 <= rd_empty;
			rd_overflow_p1	<= rd_overflow;
			rd_error_p1	<=  rd_error;
		end if;
	end process;
	
-- Module Instantiation
	Inst_ddr_sm: ddr_ctrl_sm 
	GENERIC MAP (FRAME_SIZE => FRAME_SIZE+1,
					FRAME_CNT_WIDTH => FRAME_CNT_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		MCB_CALIB_DONE => mcb_calib_done,
		WR_TRIG => wr_trig_pipe(FRAME_SIZE+1),
		SOFT_RST => ddr_soft_rst,
		DUMP_EN => dump_en,
		INIT_READ => init_rd,
		RD_ADDR => rd_addr,
		RD_DONE => rd_done,
		DDR_RDY => ddr_rdy,
		DDR_ERROR => ddr_error,
		WR_FIFO_EN => wr_fifo_en,
		FRAME_CNT_O => frame_count,
		CMD_FULL => cmd_full_p1,
		CMD_EMPTY => cmd_empty_p1,
		WR_FULL => wr_full_p1,
		WR_EMPTY => wr_empty_p1,
		WR_UNDERRUN => wr_underrun_p1,
		WR_FIFO_COUNT => wr_fifo_count,
		WR_ERROR => wr_error_p1,
		RD_FULL => rd_full_p1,
		RD_EMPTY => rd_empty_p1,
		RD_OVERFLOW => rd_overflow_p1,
		RD_ERROR => rd_error_p1,
		RD_FIFO_COUNT => rd_fifo_count,
		CMD_EN => cmd_en,
		CMD_ADDR => cmd_addr,
		CMD_BURST_LENGTH => cmd_burst_length,
		CMD_INSTR => cmd_instr 
	);
	
	Inst_wr_interface: reg_serialize 
	GENERIC MAP ( N_REGS => FRAME_SIZE+1,
					  NUM_WIDTH => NUM_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		WE => wr_trig,
		OE => wr_en_p1,
		REG_IN => reg_serial_in,
		DOUT => wr_data(NUM_WIDTH-1 downto 0)
	);
	
	Inst_trig_gen: trig_gen 
	GENERIC MAP ( CNT_WIDTH => 12 )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		TRIG_EN => '1',
		PERIOD => wr_trig_period,
		TRIG_OUT => wr_trig
	);
		
	Inst_ddr_block_regs: block_regs 
	GENERIC MAP ( N_SLV_REGS => N_SLV_REGS,
						FW_ADDR_WIDTH => FW_ADDR_WIDTH,
						FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		CS => CS,
		WE => WE,
		ADDR => ADDR,
		WB_DATA_I => DATA_I,
		WB_DATA_O => DATA_O,
		REG_DATA_I => reg_data_i,
		REG_DATA_O => reg_data_o
	);

	Inst_mcb_wrapper: mcb_wrapper 
	PORT MAP(
		SYS_CLK => DDR_CLK,
		RST => RST,
		CALIB_DONE => mcb_calib_done,
		USER_CLK => CLK,
		CMD_EN => cmd_en,
		CMD_INSTR => cmd_instr,
		CMD_BURST_LENGTH => cmd_burst_length,
		CMD_ADDR => cmd_addr,
		CMD_FULL => cmd_full,
		CMD_EMPTY => cmd_empty,
		WR_EN => wr_en_p1,
		WR_MASK => wr_mask,
		WR_DATA => wr_data,
		WR_FULL => wr_full,
		WR_EMPTY => wr_empty,
		WR_UNDERRUN => wr_underrun,
		WR_ERROR => wr_error,
		WR_FIFO_COUNT => wr_fifo_count,
		RD_EN => rd_en,
		RD_DATA => rd_data,
		RD_FULL => rd_full,
		RD_EMPTY => rd_empty,
		RD_OVERFLOW => rd_overflow,
		RD_ERROR => rd_error,
		RD_FIFO_COUNT => rd_fifo_count,
		DRAM_DQ => DRAM_DQ,
		DRAM_DQS => DRAM_DQS,
		DRAM_UDQS => DRAM_UDQS,
		DRAM_RZQ => DRAM_RZQ,
		DRAM_A => DRAM_A,
		DRAM_BA => DRAM_BA,
		DRAM_CKE => DRAM_CKE,
		DRAM_RAS_N => DRAM_RAS_N,
		DRAM_CAS_N => DRAM_CAS_N,
		DRAM_WE_N => DRAM_WE_N,
		DRAM_DM => DRAM_DM,
		DRAM_UDM => DRAM_UDM,
		DRAM_CLK => DRAM_CLK,
		DRAM_CLK_N => DRAM_CLK_N
	);

end Behavioral;

