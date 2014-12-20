----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    15:19:40 09/11/2013 
-- Design Name: 
-- Module Name:    pwm_gen_v2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
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

entity pwm_gen_v2 is
	 Generic ( CNT_WIDTH : integer := 16 );
    Port ( CLK : in  STD_LOGIC;
           EN : in  STD_LOGIC;
           PERIOD_TRIG : in  STD_LOGIC;
           SAWTOOTH : in  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
           RISE_THRESH : in  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
           FALL_THRESH : in  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
           PWM_O : out  STD_LOGIC);
end pwm_gen_v2;

architecture Behavioral of pwm_gen_v2 is

	signal rise_th_p1 : unsigned (CNT_WIDTH-1 downto 0);
	signal fall_th_p1 : unsigned (CNT_WIDTH-1 downto 0);
	
	signal fall_th_p2 : unsigned (CNT_WIDTH-1 downto 0);
	
	signal rise_pulse : std_logic;
	signal fall_pulse : std_logic;
	signal fall_pulse_p2 : std_logic;
	
begin

-- Synchronous Logic
	process (CLK) 
		variable rise_fall_case : std_logic_vector(2 downto 0);
	begin
		rise_fall_case := rise_pulse & fall_pulse & fall_pulse_p2;
		if rising_edge (CLK) then
			if (EN = '0') then
				PWM_O <= '0';
			else 
				case (rise_fall_case) is 
					when b"001" =>
						PWM_O <= '0';
					when b"011" =>
						PWM_O <= '0';
					when b"100" =>
						PWM_O <= '1';
					when b"101" =>
						PWM_O <= '1';
					when others =>
						null;					
				end case;
			end if;
		end if;
	end process;
	
	process (CLK) 
	begin
		if rising_edge (CLK) then
			rise_pulse <= '0';		-- default state
			fall_pulse <= '0';
			fall_pulse_p2 <= '0';
			if (EN = '1') then
				if (unsigned(SAWTOOTH) = rise_th_p1) then
					rise_pulse <= '1';
				end if;
				if (unsigned(SAWTOOTH) = fall_th_p1) then
					fall_pulse <= '1';
				end if;
				if (unsigned(SAWTOOTH) = fall_th_p2) then
					fall_pulse_p2 <= '1';
				end if;			
			end if;
		end if;
	end process;
		
	-- Buffers
	process (CLK) 
	begin
		if rising_edge (CLK) then
			if (EN = '0') then
				rise_th_p1 <= (others => '0');
				fall_th_p1 <= (others => '0');
			elsif (PERIOD_TRIG = '1') then
				rise_th_p1 <= unsigned(RISE_THRESH);
				fall_th_p1 <= unsigned(FALL_THRESH);				
			end if;
		end if;
	end process;
	
	process (CLK) 
	begin
		if rising_edge (CLK) then
			if (EN = '0') then
				fall_th_p2 <= (others => '0');
			elsif (rise_pulse = '1') then
				fall_th_p2 <= fall_th_p1;		
			end if;
		end if;
	end process;
		
end Behavioral;

