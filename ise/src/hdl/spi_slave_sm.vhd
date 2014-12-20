----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:31:35 05/17/2013 
-- Design Name: 
-- Module Name:    spi_slave_sm - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- Dependencies: 
--				Based of SPI_CLK, SS and MOSI, emulates the behaviour of a SPI Slave. 
--				Reads out the contents of internal registers, on MISO, at negedge of SPI_CK, based on channel address.
--				Channel Address is latched, serially on MOSI, at posedge of SPI_CK. Channel Address is 3 bits. 
--				
--				No. of channels is a Generic Parameter, with a max of 8 channels.
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

use work.regsize_calc.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave_sm is
	Generic (N_CHANNELS : integer := 4; 
				CHANNEL_WIDTH : integer := 12);
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  -- Input Values
			  REG_IN : in  STD_LOGIC_VECTOR (N_CHANNELS*CHANNEL_WIDTH-1 downto 0);
			  -- SPI Interface
           SPI_CK : in  STD_LOGIC;
           SPI_SS_n : in  STD_LOGIC;
           MOSI : in  STD_LOGIC;
           MISO : out  STD_LOGIC );
end spi_slave_sm;
  
architecture Behavioral of spi_slave_sm is

	type state_type is (	IDLE, FRAME_START, FRAME_WAIT ); 
	
   signal state, next_state : state_type; 		--Mealy State Machine

	signal sck_posedge	: std_logic;
	signal sck_negedge	: std_logic;
	signal clk_div_p1 : std_logic;	
	
	signal int_rst : std_logic;
	
	signal dsr_i	: std_logic_vector (2 downto 0);
	
	signal csr : std_logic_vector (14 downto 0);
	signal csr_d : std_logic;
	
	signal dsr_o	: std_logic_vector (CHANNEL_WIDTH-1 downto 0);
	signal dsr_o_ld : std_logic;
	
	signal reg_sel : std_logic_vector(2 downto 0);
	signal reg_sel_ld : std_logic;
	
	signal reg_in_mux : std_logic_vector(CHANNEL_WIDTH-1 downto 0);	
	
	signal reg_in_comp : unsigned(CHANNEL_WIDTH-1 downto 0);

begin

	dsr_o_ld <= csr(2);
	
	sck_posedge <= SPI_CK and (not clk_div_p1);
	sck_negedge <= clk_div_p1 and (not SPI_CK);
	
	reg_sel_ld <= csr(4);
	
	MISO <= dsr_o(CHANNEL_WIDTH-1);
	
	csr_d <= '1' WHEN (state = FRAME_START) ELSE '0';	
	
	int_rst <= '1' WHEN (state = IDLE) ELSE '0';
	
	process (REG_IN, reg_sel)
	begin	
		reg_in_mux <= REG_IN(CHANNEL_WIDTH-1 downto 0);				--default case			
		for i in 1 to N_CHANNELS-1 loop
			if (reg_sel =	std_logic_vector(to_unsigned(i, 3))) then
				reg_in_mux <= REG_IN((i+1)*CHANNEL_WIDTH-1 downto i*CHANNEL_WIDTH);
			end if;
		end loop;	
	end process;
	
	STATE_TRANSITION: process (state, SPI_SS_n, csr)
	begin
		next_state <= state;		-- to avoid latches
		case (state) is
			when IDLE =>
				if (SPI_SS_n = '0') then
					next_state <= FRAME_START;
				end if;
			when FRAME_START => 
				if (SPI_SS_n = '1') then
					next_state <= IDLE;
				else
					next_state <= FRAME_WAIT;
				end if;
			when FRAME_WAIT =>
				if (SPI_SS_n = '1') then
					next_state <= IDLE;
				elsif (csr(14) = '1') then
					next_state <= FRAME_START;
				end if;
			when others =>
				next_state <= IDLE;
		end case;
	end process;
	
-- Arithmetic Operation
	-- Converting input signed values to unsigned by adding offset
	reg_in_comp <= unsigned(reg_in_mux) + ('1' & (CHANNEL_WIDTH-2 downto 0 => '0'));

--Synchronous Logic
	REG_SEL_REG: process (CLK)
	begin
		if rising_edge (CLK) then
			if int_rst = '1' then
				reg_sel <= (others => '0');
			elsif ((sck_posedge = '1') and (reg_sel_ld = '1')) then
				reg_sel <= dsr_i;
			end if;
		end if;
	end process;


	DATA_IN_SHIFT_REG: process (CLK)
	begin
		if rising_edge(CLK) then
			if (sck_posedge = '1') then
				dsr_i <= dsr_i(1 downto 0) & MOSI;
			end if;
		end if;
	end process;
	
	CONTROL_SHIFT_REG: process (CLK)
	begin
		if rising_edge(CLK) then
			if int_rst = '1' then
				csr <= (others => '0');
			elsif (sck_negedge = '1') then
				csr <= csr(13 downto 0) & csr_d;
			end if;
		end if;
	end process;	
	
	DATA_OUT_SHIFT_REG: process (CLK)
	begin
		if rising_edge(CLK) then
			if (sck_negedge = '1') then
				if (dsr_o_ld = '1') then
					dsr_o <= std_logic_vector(reg_in_comp);
				else
					dsr_o <= dsr_o(CHANNEL_WIDTH-2 downto 0) & '0';
				end if;
			end if;
		end if;
	end process;
	
	

	STATE_UPDATE: process (CLK, RST)
	begin
		if RST = '1' then
			state <= IDLE;
		elsif rising_edge(CLK) then
			if (sck_negedge = '1') then
				state <= next_state;
			end if;
		end if;
	end process;
		
	MISC_BUFFERS: process (CLK)
	begin
		if rising_edge (CLK) then
			clk_div_p1 <= SPI_CK;
		end if;
	end process;
	
end Behavioral;

