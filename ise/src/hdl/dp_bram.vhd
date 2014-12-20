----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:31:51 08/07/2013 
-- Design Name: 
-- Module Name:    dp_bram - Behavioral 
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

use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dp_bram is
	  generic ( DATA_WIDTH 	: integer := 32;
					ADDR_WIDTH 	: integer := 5 );
	  port (
			 clka 	: IN STD_LOGIC;
			 wea 		: IN STD_LOGIC;
			 addra 	: IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
			 dina 	: IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			 clkb 	: IN STD_LOGIC;
			 addrb 	: IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
			 doutb 	: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
	  );
end dp_bram;

architecture Behavioral of dp_bram is

	type RAM_TYPE is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector (DATA_WIDTH-1 downto 0);
	
	signal RAM	: RAM_TYPE;
	
begin

	process (clka)
	begin
		if rising_edge(clka) then
			if wea = '1' then
				RAM(conv_integer(addra)) <= dina;
			end if;
		end if;
	end process;

	process (clkb)
	begin
		if rising_edge(clkb) then
			doutB <= RAM(conv_integer(addrb));
		end if;
	end process;

end Behavioral;

