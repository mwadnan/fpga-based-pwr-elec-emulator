----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:53:30 09/17/2013 
-- Design Name: 
-- Module Name:    moving_avg_filter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Implements a moving average filter, with a fixed filter gain (for all taps)
--
--			Input is assumed to be binary
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

use work.regsize_calc.all;

entity moving_avg_filter is
	Generic ( WINDOW_SZ : integer := 64;
				 NUM_WIDTH : integer := 16
				 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           EN : in  STD_LOGIC;
           FILT_COEFF : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
			  FILT_ORDER : in  STD_LOGIC_VECTOR (clog2(WINDOW_SZ)-1 downto 0);
           INPUT : in  STD_LOGIC;
           OUTPUT : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0)
			  );
end moving_avg_filter;

architecture Behavioral of moving_avg_filter is

	signal in_buffer : std_logic_vector(WINDOW_SZ-1 downto 0);
	
	signal accumulator : unsigned (NUM_WIDTH downto 0);
	signal acc_add : unsigned (NUM_WIDTH downto 0);
	signal acc_sub : unsigned (NUM_WIDTH downto 0);
	
	signal fifo_out : std_logic;

begin
-- Combinational Logic
	acc_add <= '0' & (unsigned(FILT_COEFF) and (NUM_WIDTH-1 downto 0 => INPUT));
	acc_sub <= '0' & (unsigned(FILT_COEFF) and (NUM_WIDTH-1 downto 0 => fifo_out));

	process (CLK)
	begin
		if rising_edge (CLK) then
			fifo_out <= in_buffer(to_integer(unsigned(FILT_ORDER)));
		end if;
	end process;

	process (accumulator)
	begin
		if (accumulator(NUM_WIDTH) = '1') then
			OUTPUT <= (others => '1');
		else
			OUTPUT <= std_logic_vector(accumulator(NUM_WIDTH-1 downto 0));
		end if;
	end process;

-- Synchronous Logic
	process (CLK) 
	begin
		if rising_edge (CLK) then
			in_buffer <= in_buffer(WINDOW_SZ-2 downto 0) & INPUT;
		end if;
	end process;
	
	process (CLK) 
	begin
		if rising_edge(CLK) then
			if (RST = '1') then
				accumulator <= (others => '0');
			elsif (EN = '1') then
				accumulator <= accumulator + acc_add - acc_sub;
			end if;
		end if;
	end process;

end Behavioral;

