----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    13:34:01 04/17/2013 
-- Design Name: 
-- Module Name:    ddr_ctrl_sm - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--					1. Operates in two modes: IDLE and DUMP
--					2. Generates read/write commands to MCB					
--					3. Maintains the next write_address of the DDR memory
--					4. Maintains a count of data bursts written to memory
--					5. Control signals from software can:
--							a. Reset addressing
--							b. Switch modes
--							c. Initiate a Read operation
--
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

entity ddr_ctrl_sm is
	 Generic ( FRAME_SIZE : integer := 10;
				 FRAME_CNT_WIDTH : integer := 18 );
    Port ( CLK 				: in  STD_LOGIC;
           RST 				: in  STD_LOGIC;
           EN 					: in  STD_LOGIC;
			  MCB_CALIB_DONE	: in 	STD_LOGIC;
			  -- Control Signals
			  WR_TRIG 			: in  STD_LOGIC;
			  SOFT_RST			: in  STD_LOGIC;
			  DUMP_EN 			: in  STD_LOGIC;
			  INIT_READ 		: in  STD_LOGIC;
			  RD_ADDR 			: in  STD_LOGIC_VECTOR (29 downto 0);
			  -- FSM Outputs
			  RD_DONE			: out STD_LOGIC;
			  DDR_RDY			: out STD_LOGIC;
			  DDR_ERROR			: out STD_LOGIC;
			  WR_FIFO_EN		: out STD_LOGIC;
			  FRAME_CNT_O		: out STD_LOGIC_VECTOR (FRAME_CNT_WIDTH-1 downto 0);
			  -- MCB Inputs
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
			  -- MCB Outputs
			  CMD_EN				: out  STD_LOGIC;
			  CMD_ADDR 			: out  STD_LOGIC_VECTOR (29 downto 0);
			  CMD_BURST_LENGTH : out  STD_LOGIC_VECTOR (5 downto 0);
			  CMD_INSTR 		: out  STD_LOGIC_VECTOR (2 downto 0)			  
			  );
end ddr_ctrl_sm;

architecture Behavioral of ddr_ctrl_sm is

   type state_type is (	STARTUP, IDLE, DUMP, WR_CMD, RD_CMD, ERROR_ST ); 
	
   signal state, next_state : state_type; 		--Mealy State Machine
	
	signal wr_addr				: std_logic_vector (29 downto 0);
	signal wr_addr_i			: unsigned (29 downto 0);
	signal frame_cnt			: std_logic_vector (FRAME_CNT_WIDTH downto 0);
	signal frame_cnt_i		: unsigned (FRAME_CNT_WIDTH downto 0);
		
	signal error_cond : std_logic;
	signal wr_fifo_lim : std_logic;
	signal frame_cnt_lim : std_logic;
	
	signal init_rd_p1 : std_logic;
	signal init_rd_posedge : std_logic;

begin
-- Combinational Logic
	RD_DONE <= not RD_EMPTY;
	FRAME_CNT_O <= frame_cnt(FRAME_CNT_WIDTH-1 downto 0);
		
	init_rd_posedge <= INIT_READ and (not init_rd_p1);
	
	error_cond <= WR_ERROR or WR_UNDERRUN or CMD_FULL or WR_FULL or RD_ERROR or RD_OVERFLOW;
	frame_cnt_lim <= frame_cnt(FRAME_CNT_WIDTH);
								
	-- State Transition
	process (state, SOFT_RST, DUMP_EN, MCB_CALIB_DONE, WR_TRIG, 
											init_rd_posedge, error_cond, frame_cnt_lim)
	begin
		next_state <= state;		-- to avoid latching
		case (state) is
			when STARTUP =>
				if (MCB_CALIB_DONE = '1') then
					next_state <= IDLE;
				end if;
			when IDLE =>
				if ((DUMP_EN = '1') and (frame_cnt_lim = '0')) then
					next_state <= DUMP;
				elsif (init_rd_posedge = '1') then
					next_state <= RD_CMD;
				elsif (error_cond = '1') then
					next_state <= ERROR_ST;
				end if;
			when DUMP =>
				if (WR_TRIG = '1') then
					next_state <= WR_CMD;
				elsif ((DUMP_EN = '0') or (frame_cnt_lim = '1')) then
					next_state <= IDLE;
				end if;
			when WR_CMD => 
				next_state <= DUMP;
			when RD_CMD =>
				next_state <= IDLE;
			when ERROR_ST =>
				if (SOFT_RST = '1') then
					next_state <= STARTUP;
				end if;
			when others =>
				next_state <= STARTUP;
		end case;
	end process;
	
	-- State Machine Outputs
	WR_FIFO_EN <= '1' WHEN ((state = DUMP) or (state = WR_CMD)) ELSE '0';
	
	CMD_EN <= '1' WHEN ((state = WR_CMD) or (state = RD_CMD)) ELSE '0';
	
	DDR_ERROR <= '1' WHEN (state = ERROR_ST) ELSE '0';
	
	DDR_RDY <= '0' WHEN (state = STARTUP) ELSE '1';
	
	process (state, wr_addr, frame_cnt)
	begin
		if (state = WR_CMD) then
			wr_addr_i <= unsigned(wr_addr) + to_unsigned (FRAME_SIZE*4, 30);					-- Incrementing in 32-bit words (4 Bytes)
			frame_cnt_i <= unsigned(frame_cnt) + to_unsigned (1, FRAME_CNT_WIDTH);
		else
			wr_addr_i <= unsigned(wr_addr);
			frame_cnt_i <= unsigned(frame_cnt);
		end if;
	end process;
		
	process (state, wr_addr, RD_ADDR) 
	begin
		if (state = WR_CMD) then
			CMD_ADDR <= wr_addr;
			CMD_BURST_LENGTH <= std_logic_vector(to_unsigned (FRAME_SIZE-1, 6));
			CMD_INSTR <= b"000";			--Write												
		elsif (state = RD_CMD) then
			CMD_ADDR <= RD_ADDR;
			CMD_BURST_LENGTH <= (others => '0');
			CMD_INSTR <= b"001";			--Read						
		else
			-- don't care
			CMD_ADDR <= (others => '0');
			CMD_BURST_LENGTH <= (others => '0');
			CMD_INSTR <= (others => '0');					
		end if;
	end process;
		
-- Sequential Logic	
	process (CLK, RST)
	begin
		if RST = '1' then
			state <= STARTUP;
		elsif rising_edge(CLK) then
			if EN = '1' then			
				state <= next_state;				-- State Update
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			if (RST = '1') or (SOFT_RST = '1') then
				wr_addr <= (others => '0');
				frame_cnt <= (others => '0');
			elsif EN = '1' then
				wr_addr <= std_logic_vector(wr_addr_i);
				frame_cnt <= std_logic_vector(frame_cnt_i);
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK)	then
			init_rd_p1 <= INIT_READ;
		end if;
	end process;

end Behavioral;

