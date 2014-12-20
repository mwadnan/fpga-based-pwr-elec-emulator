----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:32:32 09/02/2013 
-- Design Name: 
-- Module Name:    cpu_calc_wrapper - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu_calc_wrapper is
	Generic ( N_SLV_REGS : integer := 4;
				 N_IN_VALS : integer := 5;
				 N_OUT_VALS : integer := 2;
				 NUM_WIDTH : integer := 16;
				 FW_DATA_WIDTH : integer := 32;
				 FW_ADDR_WIDTH : integer := 8 
				 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           EN : in  STD_LOGIC;
           CS : in  STD_LOGIC;
           WE : in  STD_LOGIC;
           ADDR : in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
           DATA_I : in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
           DATA_O : out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  INTR_OUT : out STD_LOGIC;
           NUM_IN : in  STD_LOGIC_VECTOR (N_IN_VALS*NUM_WIDTH-1 downto 0);
           NUM_OUT : out  STD_LOGIC_VECTOR (N_OUT_VALS*NUM_WIDTH-1 downto 0)
			  );
end cpu_calc_wrapper;

architecture Behavioral of cpu_calc_wrapper is
	
	COMPONENT block_regs
	GENERIC ( N_SLV_REGS 	: integer;
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer );
	PORT ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           CS : in  STD_LOGIC;
           WE : in  STD_LOGIC;
           ADDR : in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
           WB_DATA_I : in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
           WB_DATA_O : out STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  REG_DATA_I : in STD_LOGIC_VECTOR (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
           REG_DATA_O : out STD_LOGIC_VECTOR (N_SLV_REGS*FW_DATA_WIDTH-1 downto 0)
			);
	END COMPONENT;		
			
	COMPONENT trig_gen
	GENERIC ( CNT_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		TRIG_EN : IN std_logic;
		PERIOD : IN std_logic_vector(CNT_WIDTH-1 downto 0);          
		TRIG_OUT : OUT std_logic
		);
	END COMPONENT;
	
	-- Control Register
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	signal interrupt_en	: std_logic;
	signal period		: std_logic_vector(11 downto 0);
	
	signal calc_trig : std_logic;
	signal in_reg : std_logic_vector(N_IN_VALS*NUM_WIDTH-1 downto 0);
	
	signal out_val : std_logic_vector(N_OUT_VALS*NUM_WIDTH-1 downto 0);

begin
	INTR_OUT <= calc_trig;

-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping in Excel documentation)
	interrupt_en 					<= reg_data_o(0);
	period 							<= reg_data_o(12 downto 1);
	
ASSIGN_OUTPUTS:
	for i in 0 to N_OUT_VALS-1 generate
	begin
		out_val((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH) <= reg_data_o((i+1)*NUM_WIDTH+31 downto i*NUM_WIDTH+32);
	end generate;
	
	reg_data_i(31 downto 0) <= (31 downto 0 => '0');
	
ASSIGN_INPUTS: process (in_reg)
	begin
		reg_data_i(N_SLV_REGS*FW_DATA_WIDTH-1 downto 32) <= (N_SLV_REGS*FW_DATA_WIDTH-1 downto 32 => '0');
		for i in 0 to N_IN_VALS-1 loop
			reg_data_i((i+1)*NUM_WIDTH+31 downto i*NUM_WIDTH+32) <= in_reg((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH);
		end loop;
	end process;
	
-- Synchronous Logic
	process (CLK)
	begin
		if rising_edge(CLK) then
			if (calc_trig = '1') then
				in_reg <= NUM_IN;
				NUM_OUT <= out_val;
			end if;
		end if;
	end process;
	
-- Module Instantiations
	Inst_trig_gen: trig_gen 
	GENERIC MAP ( CNT_WIDTH => 12 )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		TRIG_EN => interrupt_en,
		PERIOD => period,
		TRIG_OUT => calc_trig
	);
	
	Inst_cpu_calc_block_regs: block_regs 
	GENERIC MAP ( N_SLV_REGS => N_SLV_REGS,
						FW_ADDR_WIDTH => FW_ADDR_WIDTH,
						FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		CS => CS,
		WE => WE,
		ADDR => ADDR,
		WB_DATA_I => DATA_I,
		WB_DATA_O => DATA_O,
		REG_DATA_I => reg_data_i,
		REG_DATA_O => reg_data_o
	);

end Behavioral;

