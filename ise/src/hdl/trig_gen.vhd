----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:44:13 08/12/2013 
-- Design Name: 
-- Module Name:    trig_gen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Generates a TRIG pulse, after the count specified by (PERIOD) has elapsed. 
--			The count is incremented using input clock and a clock enable (CE)
--					CE is generated internally - The input CLK is divided by CLKDIV
--
--			PERIOD is latched in after every TRIG, so as to account for changes
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--		Assumption:
--			CLK_DIV is power of two
--			If CLK_DIV < 4, then actual trigger period is larger than PERIOD by 1(CLK_DIV=2) or 2(CLK_DIV=1) cycles
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

use work.regsize_calc.all;

entity trig_gen is
	 Generic ( CLK_DIV : integer := 4;
				  -- Parameters above are NOT set in a higher hierarchy 
				  CNT_WIDTH : integer := 8 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           EN : in  STD_LOGIC;
			  TRIG_EN : in  STD_LOGIC;
           PERIOD : in  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
           TRIG_OUT : out  STD_LOGIC);
end trig_gen;

architecture Behavioral of trig_gen is

	signal ce : std_logic;
	signal clkdiv : std_logic;
	signal clkdiv_p1 : std_logic;
	signal clkdiv_cnt : unsigned(clog2(CLK_DIV)-1 downto 0);

	signal cnt : unsigned (CNT_WIDTH-1 downto 0);
		
	signal trig_cond : std_logic;
	signal trig_cond_p1 : std_logic;
	signal trig_cond_p2 : std_logic;
	
	signal trig : std_logic;
	
begin

	trig <= TRIG_EN and (trig_cond_p1 and (not trig_cond_p2));		--positive edge

	trig_cond <= '1' WHEN (cnt = (CNT_WIDTH-1 downto 0 => '0')) ELSE '0';
	
UNITY_CLK_DIV:	if (CLK_DIV = 1) generate
	begin
		ce <= '1';
	end generate;
	
NONUNITY_CLK_DIV:	if (CLK_DIV > 1) generate
	begin
		ce <= clkdiv and (not clkdiv_p1);
	end generate;
	
	clkdiv <= std_logic(clkdiv_cnt(clog2(CLK_DIV)-1));				-- Clock divided by CLK_DIV

-- Synchronous Logic
	process (CLK)
	begin
		if rising_edge(CLK) then
			TRIG_OUT <= trig;
		end if;
	end process;

	process (CLK)
	begin
		if rising_edge (CLK) then
			if ((RST = '1') or (trig_cond_p1 = '1'))  then
				cnt <= unsigned(PERIOD);
			elsif (ce = '1') then
				cnt <= cnt - 1;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge(CLK) then
			if (RST = '1') then
				clkdiv_cnt <= (others => '0');
			else
				clkdiv_cnt <= clkdiv_cnt+1;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			trig_cond_p1 <= trig_cond;
			trig_cond_p2 <= trig_cond_p1;
			clkdiv_p1 <= clkdiv;
		end if;
	end process;

end Behavioral;

