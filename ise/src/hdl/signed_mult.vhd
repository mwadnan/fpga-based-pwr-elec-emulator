----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
--
-- Create Date:    13:54:33 07/25/2013 
-- Design Name: 
-- Module Name:    signed_mult - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--		Computes P = A * B
--		Assumptions
--		1. Signed fixed point operands.
--		2. Operands have the same width
--		3. Result has same width as operands
--
--		Saturates upon overflow
-- 	Uses a DSP48 Primitive, with a latency of 1 clock cycle.
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
library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity signed_mult is
	 GENERIC (NUM_WIDTH : integer := 16 );
    Port ( CLK : in  STD_LOGIC;
			  RST : in  STD_LOGIC;
			  A : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           B : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           P : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0));
end signed_mult;

architecture Behavioral of signed_mult is

	signal product : std_logic_vector(2*NUM_WIDTH-1 downto 0);
	
	signal ovf : std_logic;

begin

	-- Overflow check + Saturation
	ovf <= product(2*NUM_WIDTH-1) xor product(2*NUM_WIDTH-2);	
	
	process (product, ovf)
	begin
		if (ovf = '1') then
			P <= product(2*NUM_WIDTH-1) & (NUM_WIDTH-2 downto 0 => product(2*NUM_WIDTH-2));		-- positive or negative max
		else
			P <= product(2*NUM_WIDTH-2 downto NUM_WIDTH-1);		-- discarding extra sign bit due to signed multiplication
		end if;
	end process;
			
	MULT_MACRO_inst : MULT_MACRO
   generic map (
      DEVICE => "SPARTAN6",    -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      LATENCY => 3,           -- Desired clock cycle latency, 0-4
      WIDTH_A => NUM_WIDTH,          -- Multiplier A-input bus width, 1-25 
      WIDTH_B => NUM_WIDTH)          -- Multiplier B-input bus width, 1-18
   port map (
      P => product,     -- Multiplier ouput bus, width determined by WIDTH_P generic 
      A => A,     -- Multiplier input A bus, width determined by WIDTH_A generic 
      B => B,     -- Multiplier input B bus, width determined by WIDTH_B generic 
      CE => '1',   -- 1-bit active high input clock enable
      CLK => CLK, -- 1-bit positive edge clock input
      RST => RST  -- 1-bit input active high reset
   );


end Behavioral;

