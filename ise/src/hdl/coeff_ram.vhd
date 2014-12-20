----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:56:17 08/07/2013 
-- Design Name: 
-- Module Name:    coeff_ram - Behavioral 
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

entity coeff_ram is
	 generic ( 	WR_DATA_WIDTH 	: integer := 32;
					RD_ADDR_WIDTH 	: integer := 5;
					RD_DATA_WIDTH 	: integer := 128;			-- Has to be multiples of 16
					WR_ADDR_WIDTH 	: integer := 7 );			-- Has to >= RD_ADDR_WIDTH
	  port (
			 clka 	: IN STD_LOGIC;
			 wea 		: IN STD_LOGIC;
			 addra 	: IN STD_LOGIC_VECTOR(WR_ADDR_WIDTH-1 DOWNTO 0);
			 dina 	: IN STD_LOGIC_VECTOR(WR_DATA_WIDTH-1 DOWNTO 0);
			 clkb 	: IN STD_LOGIC;
			 addrb 	: IN STD_LOGIC_VECTOR(RD_ADDR_WIDTH-1 DOWNTO 0);
			 doutb 	: OUT STD_LOGIC_VECTOR(RD_DATA_WIDTH-1 DOWNTO 0)
	  );
end coeff_ram;

architecture Behavioral of coeff_ram is

	constant RATIO : integer := (2**(WR_ADDR_WIDTH - RD_ADDR_WIDTH));		
	
	COMPONENT dp_bram
	GENERIC ( DATA_WIDTH 	: integer := 32;
				 ADDR_WIDTH 	: integer := 5 );
	PORT (
		 clka 	: IN STD_LOGIC;
		 wea 		: IN STD_LOGIC;
		 addra 	: IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
		 dina 	: IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
		 clkb 	: IN STD_LOGIC;
		 addrb 	: IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
		 doutb 	: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
	);
	END COMPONENT;	
	
	signal rd_data : std_logic_vector (RATIO*WR_DATA_WIDTH-1 downto 0);
	
	signal we : std_logic_vector (RATIO-1 downto 0);			-- Different WE for each Block (Based on lower bits of addrA)
	
begin

	doutb <= rd_data(RD_DATA_WIDTH-1 downto 0);

RATIO_1:
	if (RATIO = 1) generate
	begin
		we <= (RATIO-1 downto 0 => wea);
	end generate;
	
RATIO_GT1:
	if (RATIO >= 2) generate
	begin
		-- Decoder (log2(RATIO) : RATIO)
		process (wea, addra)
		begin
			if (wea = '1') then
				we <= (others => '0');
				we(to_integer(unsigned(addra(WR_ADDR_WIDTH - RD_ADDR_WIDTH-1 downto 0)))) <= '1';
			else
				we <= (others => '0');
			end if;
		end process;
	end generate;

MULTIPLE_RAM_BLOCKS:
	for i in 0 to RATIO-1 generate
	begin
		block_i: dp_bram 
		GENERIC MAP (DATA_WIDTH => WR_DATA_WIDTH,
						 ADDR_WIDTH => RD_ADDR_WIDTH )
		PORT MAP(
			clka => clka,
			wea => we(i),
			addra => addra(WR_ADDR_WIDTH-1 downto WR_ADDR_WIDTH - RD_ADDR_WIDTH),
			dina => dina,
			clkb => clkb,
			addrb => addrb,
			doutb => rd_data((i+1)*WR_DATA_WIDTH-1 downto i*WR_DATA_WIDTH) 
		);
	end generate;


end Behavioral;

