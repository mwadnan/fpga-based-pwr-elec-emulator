----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    18:49:49 04/25/2013 
-- Design Name: 
-- Module Name:    wb_slave_interface - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Three main functions:
--				1. Provide synchronization mechanism for clock boundary (i.e from CPU_CLK to CLK)
--						Assumption - CLK is faster than CPU_CLK
--				2. From Wishbone bus's ADDRESS bus, generate Chip-selects (CS) and Register Addresses for individual FW Blocks
--				3. Multiplex DOUT busses from different Firmware blocks into the data bus.
--
-- Dependencies: 
--			It is assumed that data on the busses FW_DOUT remains valid for multiple cycles of CLK, so it doesnt voilate any hold-time constraints for CPU_CLK
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--		3-flop clock synchronization is used to avoid metastable states.
--		Naming convention for internal signals:
--			 "c1_" prefix represents signals in 1st pipeline stage of CPU_CLK Domain
--			 "c2_" prefix represents signals in 2nd pipeline stage of CPU_CLK Domain
--			 "s1_" prefix represents signals in 1st pipeline stage of CLK Domain
--			 "s2_" prefix represents signals in 2nd pipeline stage of CLK Domain
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use work.reduction_op.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_slave_interface is
	Generic ( N_WB_SLAVES : integer := 2; 
				 FW_ADDR_WIDTH : integer := 8;
				 FW_DATA_WIDTH : integer := 32);
	Port ( CLK			: in  STD_LOGIC;
			 CPU_CLK		: in  STD_LOGIC;
			 RST			: in  STD_LOGIC;
			 -- Wishbone Bus Signals
			 WB_DATA_I		: in  STD_LOGIC_VECTOR(31 downto 0);
			 WB_ADDR			: in  STD_LOGIC_VECTOR(31 downto 0);
			 WB_STRB			: in  STD_LOGIC;
			 WB_CYC			: in  STD_LOGIC;
			 WB_WE			: in  STD_LOGIC;
			 WB_ACK			: out STD_LOGIC;
			 WB_ERR			: out STD_LOGIC;
			 WB_RTY			: out STD_LOGIC;
			 WB_INTR			: out STD_LOGIC;
			 WB_DATA_O		: out  STD_LOGIC_VECTOR(31 downto 0);
			 -- Firmware Blocks' Signals
			 FW_INTERRUPT	: in  STD_LOGIC;	
			 FW_DOUT_COMB	: in  STD_LOGIC_VECTOR(FW_DATA_WIDTH*N_WB_SLAVES - 1 downto 0);
			 FW_CS 			: out  STD_LOGIC_VECTOR (N_WB_SLAVES-1 downto 0);
			 FW_WE 			: out  STD_LOGIC;
			 FW_DIN 			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			 FW_ADDR 		: out  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0)
			);
end wb_slave_interface;

architecture Behavioral of wb_slave_interface is

	constant WB_SLAVE_BASEADDR	: std_logic_vector(31 downto 0) := x"80000000";
	
	signal c1_CS		: std_logic_vector (N_WB_SLAVES-1 downto 0);
	signal s1_CS	: std_logic_vector (N_WB_SLAVES-1 downto 0);
	signal s2_CS	: std_logic_vector (N_WB_SLAVES-1 downto 0);
	
	signal c1_ADDR		: std_logic_vector (FW_ADDR_WIDTH-1 downto 0);
	signal s1_ADDR		: std_logic_vector (FW_ADDR_WIDTH-1 downto 0);
	signal s2_ADDR		: std_logic_vector (FW_ADDR_WIDTH-1 downto 0);
		
	signal c1_DIN		: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	signal s1_DIN		: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	signal s2_DIN		: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
		
	signal c1_WE	: std_logic;
	signal s1_WE	: std_logic;
	signal s2_WE	: std_logic;	
	
	signal strb		: std_logic;
	signal c1_strb	: std_logic;
	signal s1_strb	: std_logic;
	signal s2_strb	: std_logic;
	
	signal ack_cond : std_logic;
	signal s1_ack : std_logic;
	signal c1_ack : std_logic;
	signal c2_ack : std_logic;
	signal c3_ack : std_logic;
	
	signal dout	: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	signal s1_dout	: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	signal c1_dout	: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	signal c2_dout	: std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	
	signal s_intr : std_logic_vector(5 downto 0);
	signal c1_intr : std_logic;
	signal c2_intr : std_logic;
	
	-- Setting attribute ASYNC_REG for all flip-flops at the clock boundary
	-- These flip-flops are for 3-flop sync. They should not be implemented using shift registers
	attribute ASYNC_REG : string;
	
	attribute ASYNC_REG of s1_strb: signal is "TRUE";
	attribute ASYNC_REG of s1_DIN: signal is "TRUE";
	attribute ASYNC_REG of s1_ADDR: signal is "TRUE";
	attribute ASYNC_REG of s1_WE: signal is "TRUE";
	attribute ASYNC_REG of s1_CS: signal is "TRUE";
	
	attribute ASYNC_REG of c1_ack: signal is "TRUE";
	attribute ASYNC_REG of c1_dout: signal is "TRUE";
	attribute ASYNC_REG of c1_intr: signal is "TRUE";

begin

-- Datapath Statements
	WB_ERR <= '0';
	WB_RTY <= '0';
	WB_INTR <= c2_intr;
	WB_ACK <= c2_ack and (not c3_ack);			
	WB_DATA_O(FW_DATA_WIDTH-1 downto 0) <= c2_dout;
	-- If data bus length on wishbone bus vs. firmware blocks is not the same
	DATA_I_UPPER: if (FW_DATA_WIDTH < 32) generate
	begin
		WB_DATA_O(31 downto FW_DATA_WIDTH) <= (31 downto FW_DATA_WIDTH => '0');
	end generate;
	
	FW_ADDR <= s2_ADDR;
	FW_DIN <= s2_DIN;
	FW_CS <= s2_CS;
	FW_WE <= s2_WE;

-- Combinational Logic	
	strb <= WB_CYC and WB_STRB;
	ack_cond <= s2_strb;
	
	-- Slave Data MUX	
	WB_DATA_MUX: process (s2_CS, FW_DOUT_COMB)
	begin
		dout <= (FW_DATA_WIDTH-1 downto 0 => '0');
		for i in 0 to N_WB_SLAVES-1 loop
			if (s2_CS(i) = '1') then
				dout <= FW_DOUT_COMB((i+1)*FW_DATA_WIDTH-1 downto i*FW_DATA_WIDTH);
			end if;
		end loop;
	end process;
	
-- Sequential Logic (CPU_CLK Domain)
	process (CPU_CLK)
	begin
		if rising_edge (CPU_CLK) then
			c1_ack <= s1_ack;
			
			c1_dout <= s1_dout;
			
			c1_intr <= or_reduce(s_intr);
		end if;
	end process;
	
	process (CPU_CLK)
	begin
		if rising_edge (CPU_CLK) then
			c2_ack <= c1_ack;
			c3_ack <= c2_ack;
			
			c2_dout <= c1_dout;
			c2_intr <= c1_intr;
		end if;
	end process;
	
	process (CPU_CLK)
	begin
		if rising_edge (CPU_CLK) then
			c1_strb <= strb;
		
			c1_DIN 	<= WB_DATA_I (FW_DATA_WIDTH-1 downto 0);
			c1_ADDR 	<= WB_ADDR (FW_ADDR_WIDTH-1 downto 0);
			c1_WE 	<= WB_WE;
					
			-- Chip-Selects and Register Addressing
			if ((strb = '1') and (WB_ADDR(31 downto 24) = WB_SLAVE_BASEADDR(31 downto 24))) then
				c1_CS <= WB_ADDR (FW_ADDR_WIDTH+N_WB_SLAVES-1 downto FW_ADDR_WIDTH);
			else
				c1_CS <= (others => '0');
			end if;
		end if;
	end process;

-- Sequential Logic (CLK Domain)
	process (CLK)
	begin
		if rising_edge (CLK) then
			s1_strb <= c1_strb;
			
			s1_DIN 	<= c1_DIN;
			s1_ADDR 	<= c1_ADDR;
			s1_WE 	<= c1_WE;
			s1_CS 	<= c1_CS;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			s2_strb <= s1_strb;
			
			s2_DIN 	<= s1_DIN;
			s2_ADDR 	<= s1_ADDR;
			s2_WE 	<= s1_WE;
			s2_CS 	<= s1_CS;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			s1_ack <= ack_cond;
			
			s1_dout <= dout;
			
			s_intr <= s_intr(4 downto 0) & FW_INTERRUPT;
		end if;
	end process;

end Behavioral;

