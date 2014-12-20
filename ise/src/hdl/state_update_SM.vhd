----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    15:21:11 07/25/2013 
-- Design Name: 
-- Module Name:    state_update_SM - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			State Machine to control the sequencing of arithmetic operations for LPV State Update Module
--
--			A valid (Updated State) value appears on X_OUT one clock cycle after FSM enters IDLE state.
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

entity state_update_SM is
	 Generic (	N_X : integer := 4;
					N_U : integer := 3;
					N_Z : integer := 2;
					BRAM_RD_ADDR_WIDTH : integer := 5 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  EN  : in  STD_LOGIC;
           UPDATE_TRIG : in  STD_LOGIC;
			  SOFT_RST	: in  STD_LOGIC;
			  DONE	: out  STD_LOGIC;
			  -- FSM Outputs
			  U_REG_EN	: out  STD_LOGIC;
			  Z_REG_EN	: out  STD_LOGIC;
           PE_IN_SEL : out  STD_LOGIC_VECTOR(1 downto 0);
           PE_OUT_SEL : out  STD_LOGIC_VECTOR(1 downto 0);
           PE_MACC_RST : out  STD_LOGIC;
           PE_MACC_SHIFT : out  STD_LOGIC;
           BRAM_ADDR : out  STD_LOGIC_VECTOR (BRAM_RD_ADDR_WIDTH-1 downto 0) );
end state_update_SM;

architecture Behavioral of state_update_SM is

	type state_type is (	STATE_INIT, INIT_UPDATE, STATE_FEEDBACK, NEXT_PARAM, INPUT_UPDATE, ADD_PREV, UPDATE_DONE, IDLE ); 
	
   signal state, next_state : state_type; 		--Moore type Finite State Machine
	
	signal addr_cnt : unsigned (BRAM_RD_ADDR_WIDTH-1 downto 0);
	signal addr_lim : std_logic;
	
	signal st_seq_in : std_logic;
	signal st_seq_out : std_logic;
	signal st_seq : std_logic_vector (N_X downto 0);
	
	signal p_seq_in : std_logic;
	signal p_seq_out : std_logic;
	signal p_seq : std_logic_vector (N_Z downto 0);
	
	signal macc_rst_cond		: std_logic;
	signal macc_rst_cond_p1	: std_logic;
	
	signal done_cond : std_logic;
	signal done_pipe : std_logic_vector(3 downto 0);
	
begin
	-- State Output (Mealy type FSM)
	DONE <= done_pipe(2) and (not done_pipe(3));			
	
	BRAM_ADDR <= std_logic_vector(addr_cnt);
	
	PE_MACC_RST <= macc_rst_cond or macc_rst_cond_p1;	
	
	PE_MACC_SHIFT <= '1' WHEN (state = UPDATE_DONE) ELSE '0';
	
	U_REG_EN <= '1' WHEN (state = INPUT_UPDATE) ELSE '0';
	
	Z_REG_EN <= st_seq_out;
	
	process (state)
	begin
		case (state) is
			when STATE_INIT =>
				PE_IN_SEL <= b"00";
				PE_OUT_SEL <= b"01";
			when INIT_UPDATE =>
				PE_IN_SEL <= b"10";
				PE_OUT_SEL <= b"11";
			when STATE_FEEDBACK =>
				PE_IN_SEL <= b"10";
				PE_OUT_SEL <= b"11";
			when NEXT_PARAM =>
				PE_IN_SEL <= b"11";
				PE_OUT_SEL <= b"11";
			when INPUT_UPDATE =>
				PE_IN_SEL <= b"01";
				PE_OUT_SEL <= b"00";
			when ADD_PREV =>
				PE_IN_SEL <= b"00";
				PE_OUT_SEL <= b"00";
			when UPDATE_DONE =>
				PE_IN_SEL <= b"00";
				PE_OUT_SEL <= b"00";
			when IDLE =>
				PE_IN_SEL <= b"00";
				PE_OUT_SEL <= b"10";
			when others => 
				PE_IN_SEL <= b"00";
				PE_OUT_SEL <= b"01";
		end case;
	end process;
	
	done_cond <= '1' WHEN (state = IDLE) ELSE '0';
	
	macc_rst_cond <= '1' WHEN ((state = INIT_UPDATE) or (state = STATE_INIT)) ELSE '0';
			
	-- FSM Inputs
	addr_lim <= '1' WHEN (addr_cnt = to_unsigned((N_Z+1)*N_X + N_U + 1, BRAM_RD_ADDR_WIDTH)) ELSE '0';
	
	st_seq_out <= st_seq(N_X-1);
	p_seq_out <= p_seq(N_Z);
	
	p_seq_in <= UPDATE_TRIG;
	
	process (UPDATE_TRIG, state, st_seq_out)
	begin
		if (UPDATE_TRIG = '1') then
			st_seq_in <= '1';
		elsif ((state = INIT_UPDATE) or (state = STATE_FEEDBACK) or (state = NEXT_PARAM)) then
			st_seq_in <= st_seq_out;
		else
			st_seq_in <= '0';
		end if;
	end process;

	-- State Transition
	process (state, UPDATE_TRIG, SOFT_RST, st_seq_out, p_seq_out, addr_lim)
	begin
		next_state <= state;
		case (state) is
			when STATE_INIT =>
				if (UPDATE_TRIG = '1') then
					next_state <= INIT_UPDATE;
				end if;
			when INIT_UPDATE =>
				if (st_seq_out = '1') then
					if (p_seq_out = '1') then
						next_state <= INPUT_UPDATE;
					else
						next_state <= NEXT_PARAM;
					end if;
				else
					next_state <= STATE_FEEDBACK;
				end if;
			when STATE_FEEDBACK =>
				if (st_seq_out = '1') then
					if (p_seq_out = '1') then
						next_state <= INPUT_UPDATE;
					else
						next_state <= NEXT_PARAM;
					end if;
				end if;
			when NEXT_PARAM =>
				if (st_seq_out = '1') then
					if (p_seq_out = '1') then
						next_state <= INPUT_UPDATE;
					else
						null;
					end if;
				else
					next_state <= STATE_FEEDBACK;
				end if;
			when INPUT_UPDATE =>
				if (addr_lim = '1') then
					next_state <= ADD_PREV;
				end if;
			when ADD_PREV =>
				next_state <= UPDATE_DONE;
			when UPDATE_DONE =>
				next_state <= IDLE;
			when IDLE =>
				if (SOFT_RST = '1') then
					next_state <= STATE_INIT;
				elsif (UPDATE_TRIG = '1') then
					next_state <= INIT_UPDATE;
				end if;
			when others => 
				next_state <= STATE_INIT;
		end case;
	end process;

-- Sequential Logic
	process (CLK, RST)
	begin
		if (RST = '1') then
			state <= STATE_INIT;
		elsif rising_edge(CLK) then
			if (EN = '1') then
				state <= next_state;
			end if;
		end if;
	end process;

	-- Sequential State Outputs
	process (CLK)
	begin
		if rising_edge(CLK) then
			st_seq <= st_seq(N_X-1 downto 0) & st_seq_in;
		end if;
	end process;
	
	N_Z_C1: if (N_Z = 0) generate
	begin
		process (CLK)
		begin
			if rising_edge(CLK) then
				if (p_seq_in = '1') then
					p_seq <= std_logic_vector(to_unsigned(1, N_Z+1));
				elsif (st_seq_out = '1') then
					p_seq <= std_logic_vector(to_unsigned(0, N_Z+1));
				end if;
			end if;
		end process;	
	end generate;	
	
	N_Z_C2: if (N_Z > 0) generate
	begin
		process (CLK)
		begin
			if rising_edge(CLK) then
				if (p_seq_in = '1') then
					p_seq <= std_logic_vector(to_unsigned(1, N_Z+1));
				elsif (st_seq_out = '1') then
					p_seq <= p_seq(N_Z-1 downto 0) & '0';
				end if;
			end if;
		end process;	
	end generate;

	process (CLK)
	begin
		if rising_edge(CLK) then
			case (state) is 
				when STATE_INIT =>
					if (UPDATE_TRIG = '1') then
						addr_cnt <= to_unsigned(1, BRAM_RD_ADDR_WIDTH);
					else
						addr_cnt <= (others => '0');
					end if;
				when IDLE =>
					if (UPDATE_TRIG = '1') then
						addr_cnt <= to_unsigned(1, BRAM_RD_ADDR_WIDTH);
					end if;
				when others =>
					addr_cnt <= addr_cnt + 1;
			end case;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge(CLK) then
			done_pipe <= done_pipe(2 downto 0) & done_cond;
			macc_rst_cond_p1 <= macc_rst_cond;
		end if;
	end process;	

end Behavioral;

