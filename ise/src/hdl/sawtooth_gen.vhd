----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    13:41:27 07/10/2013 
-- Design Name: 
-- Module Name:    sawtooth_gen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--				Generates a sawtooth/triangular waveform, on the output. 
--				COUNT_OUT is unsigned.
--				The period of output waveform is dependant on the input PERIOD. The period (in sec) is given by T = PERIOD/FClk
--				
--				At the end of the counter period, a pulse is generated on PERIOD_TRIG
--				
--				Parameter MODE distinguishes between Sawtooth or Triangular waveform 
--					MODE = 1 => SAWTOOTH (SINGLE_FALLING_EDGE PWM)
--					MODE = 0 => TRIANGULAR (DOUBLE_EDGED/CENETERED PWM)
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

entity sawtooth_gen is
	Generic (  MODE	: integer := 1;
				  -- Parameters above are NOT set in a higher hierarchy
				  CNT_WIDTH : integer := 16 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  EN	: in  STD_LOGIC;
			  PERIOD : in  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
           COUNT_OUT : out  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
			  PERIOD_TRIG : out STD_LOGIC );
end sawtooth_gen;

architecture Behavioral of sawtooth_gen is

	signal counter : unsigned (CNT_WIDTH-1 downto 0);	
	
	signal cnt_up : std_logic;			-- 1 => Increment counter; 0 => decrement counter
	signal cnt_rst : std_logic;
	
	signal cnt_st : std_logic;		-- Current State of counter (counting up('1') or counting down('0'))
	
	signal cnt_max : std_logic;
	signal cnt_min : std_logic;
	
	signal period_pulse : std_logic;
	
	signal cnt_up_p1 : std_logic;

begin
-- Combinational logic
	cnt_max <= '1' WHEN (counter(CNT_WIDTH-1 downto 0) = unsigned(PERIOD)) ELSE '0';
	cnt_min <= '1' WHEN (counter(CNT_WIDTH-1 downto 0) = (CNT_WIDTH-1 downto 0 => '0')) ELSE '0';
	
	MODE_0:
   if MODE = 0 generate
      begin
			period_pulse <= (cnt_up xor cnt_up_p1);
			
			cnt_rst <= '0';			
			cnt_up <= (cnt_st and (not cnt_max)) or cnt_min;
   end generate;	
	
	MODE_1:
   if MODE = 1 generate
      begin
			period_pulse <= cnt_max;
			
			cnt_rst <= cnt_max;			
			cnt_up <= '1';
   end generate;
	
		
-- Synchronous logic
	OUT_BUFFER: process (CLK)
	begin
		if rising_edge(CLK) then
			PERIOD_TRIG <= period_pulse;
			COUNT_OUT <= std_logic_vector(counter);
		end if;
	end process;

	count_state: process (CLK)
	begin
		if rising_edge(CLK) then
			if (cnt_min = '1') then
				cnt_st <= '1';
			elsif (cnt_max = '1') then
				cnt_st <= '0';
			end if;
		end if;
	end process;

	COUNTER_REG: process (CLK)
	begin
		if rising_edge (CLK) then
			if ((RST = '1') or (cnt_rst = '1')) then
				counter <= (others => '0');
			elsif (EN = '1') then
				if (cnt_up = '1') then
					counter <= counter + 1;
				else
					counter <= counter - 1;
				end if;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			cnt_up_p1 <= cnt_up;
		end if;
	end process;

end Behavioral;

