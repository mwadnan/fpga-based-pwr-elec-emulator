----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    12:56:54 07/25/2013 
-- Design Name: 
-- Module Name:    reg_serialize - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Implements a series of registers of width (NUM_WIDTH), connected in cascade. 
--			The registers can be written-to in parallel, when WE is asserted
--			When OE is asserted, the contents of the registers shift (word-wise), every clock cycle.
--			Above, functionality, allows to sequentially read multiple words on a single data bus.
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reg_serialize is
	Generic ( N_REGS : integer := 3;
				 NUM_WIDTH : integer := 16 );		
    Port ( CLK : in  STD_LOGIC;
			  RST : in  STD_LOGIC;
			  WE : in  STD_LOGIC;
			  OE : in  STD_LOGIC;
           REG_IN : in  STD_LOGIC_VECTOR (N_REGS*NUM_WIDTH-1 downto 0);
           DOUT : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0));
end reg_serialize;

architecture Behavioral of reg_serialize is

	signal reg : std_logic_vector(N_REGS*NUM_WIDTH-1 downto 0);

begin

	DOUT <= reg(N_REGS*NUM_WIDTH-1 downto (N_REGS-1)*NUM_WIDTH);

	process (CLK)
	begin
		if rising_edge (CLK) then
			if ((RST = '1') or (WE = '1')) then
				reg <= REG_IN;
			elsif (OE = '1') then
				reg <= reg((N_REGS-1)*NUM_WIDTH-1 downto 0) & (NUM_WIDTH-1 downto 0 => '0');
			end if;
		end if;
	end process;

end Behavioral;

