----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    16:31:44 04/26/2013 
-- Design Name: 
-- Module Name:    block_regs - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--				Provides an interface between WISHBONE Signals and Registers. 
--			No. of Register is specified by generic N_SLV_REGS
--
--			Note that the Read and Write registers are kept separate. 
--			Hence, it is NOT POSSIBLE TO READ-BACK a value on this interface.
--
--			Based on assignment of REG_DATA_I and REG_DATA_O outside this block, the flipflops for unconnected bits will be optimized out. 
--			(Expect lots of warnings!!)
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

use work.regsize_calc.all;

entity block_regs is
	Generic ( N_SLV_REGS	: integer := 1;
				 FW_ADDR_WIDTH : integer := 6;
				 FW_DATA_WIDTH : integer := 16
				 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           CS : in  STD_LOGIC;
           WE : in  STD_LOGIC;
           ADDR : in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
           WB_DATA_I : in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
           WB_DATA_O : out STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  REG_DATA_I : in STD_LOGIC_VECTOR (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
           REG_DATA_O : out STD_LOGIC_VECTOR (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0)
			  );
end block_regs;

architecture Behavioral of block_regs is

	constant A_WIDTH : integer := clog2(N_SLV_REGS);

	signal block_we : std_logic;
	
	signal wr_reg_data : std_logic_vector (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	signal rd_reg_data : std_logic_vector (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);

begin

	block_we <= CS and WE;
	
	REG_DATA_O <= wr_reg_data;
	
SINGLE_REG:
   if N_SLV_REGS = 1 generate
      begin
		
			WB_DATA_O <= rd_reg_data;	

			process (CLK)
			begin
				if rising_edge (CLK) then
					if (RST = '1') then
						wr_reg_data <= (others => '0');
					elsif (block_we = '1') then
						wr_reg_data <= WB_DATA_I;
					end if;
				end if;
			end process;
			
   end generate;
	
MULT_REGS:
   if N_SLV_REGS > 1 generate
      begin			
		
		-- MUX of data bus going to Wishbone Interface
		process (rd_reg_data, ADDR)
		begin
			WB_DATA_O <= rd_reg_data(FW_DATA_WIDTH-1 downto 0);		--lowest section by default 
			for i in 1 to N_SLV_REGS-1 loop
				if (ADDR(A_WIDTH+2-1 downto 2) = 
													std_logic_vector(to_unsigned(i, A_WIDTH))) then
					WB_DATA_O <= rd_reg_data((i+1)*FW_DATA_WIDTH-1 downto i*FW_DATA_WIDTH);
				end if;
			end loop;
		end process;
	
	-- Buffered DEMUX of Data-bus based on ADDR
	--(last two bits discarded, because of word(32-bit) addressing on Wishbone bus)
	process (CLK)
	begin
		if rising_edge(CLK) then
			if (RST = '1') then
				wr_reg_data <= (others => '0');
			elsif (block_we = '1') then
				for i in 0 to N_SLV_REGS-1 loop
					if (ADDR(A_WIDTH+2-1 downto 2) = 
												std_logic_vector(to_unsigned(i, A_WIDTH))) then
						wr_reg_data((i+1)*FW_DATA_WIDTH-1 downto i*FW_DATA_WIDTH) <= WB_DATA_I;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
	end generate;

	process (CLK)
	begin
		if rising_edge(CLK) then
			rd_reg_data <= REG_DATA_I;
		end if;
	end process;

end Behavioral;

