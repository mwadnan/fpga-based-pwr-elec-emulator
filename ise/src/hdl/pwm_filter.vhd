----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:28:34 09/17/2013 
-- Design Name: 
-- Module Name:    pwm_filter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Implements a moving average filter on the input PWM(binary) signals.
--			The filter coefficient (including any scaling factor (e.g. U_DC)) and 
--				the order of the filter are software parameters (via WISHBONE bus)
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

use work.regsize_calc.all;

entity pwm_filter is
	Generic ( N_SLV_REGS : integer := 1;
				 MAX_WINDOW : integer := 256;			-- Should be a power of 2
				 -- Parameters above are NOT set in a higher hierarchy 
				 N_CHANNELS : integer := 3;
				 NUM_WIDTH : integer := 16;
				 FW_DATA_WIDTH : integer := 32;
				 FW_ADDR_WIDTH : integer := 8 
				 );	
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           EN : in  STD_LOGIC;
			  -- WISHBONE Slave Interface 
			  CS				: in  STD_LOGIC;
			  WE				: in  STD_LOGIC;
			  ADDR			: in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
			  DATA_I			: in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  DATA_O			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  -- PWM Signals
           PWM_IN : in  STD_LOGIC_VECTOR (N_CHANNELS-1 downto 0);
           FILT_OUT : out  STD_LOGIC_VECTOR (N_CHANNELS*NUM_WIDTH-1 downto 0)
			  );
end pwm_filter;

architecture Behavioral of pwm_filter is

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
		
	COMPONENT moving_avg_filter
	GENERIC 
		( WINDOW_SZ : integer;
		  NUM_WIDTH : integer
		 );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		FILT_COEFF : IN std_logic_vector(NUM_WIDTH-1 downto 0);
		FILT_ORDER : in  STD_LOGIC_VECTOR (clog2(WINDOW_SZ)-1 downto 0);
		INPUT : IN std_logic;          
		OUTPUT : OUT std_logic_vector(NUM_WIDTH-1 downto 0)
		);
	END COMPONENT;
	
	-- Control Register
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	signal input_en 	: std_logic;
	signal filt_coeff : std_logic_vector(NUM_WIDTH-1 downto 0);	
	signal filt_order : std_logic_vector(clog2(MAX_WINDOW)-1 downto 0);
	
	signal pwm_p1 : std_logic_vector(N_CHANNELS-1 downto 0);
	signal pwm_p2 : std_logic_vector(N_CHANNELS-1 downto 0);
	signal pwm_gated : std_logic_vector(N_CHANNELS-1 downto 0);
	
begin

-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping in Excel documentation)
	input_en 						<= reg_data_o(0);
	filt_coeff						<= reg_data_o(NUM_WIDTH+1-1 downto 1);
	filt_order						<= reg_data_o(clog2(MAX_WINDOW)+NUM_WIDTH+1-1 downto NUM_WIDTH+1);
	
	reg_data_i(31 downto 0) 	<= (others => '0');
	
-- Combinational Logic
	pwm_gated <= pwm_p2 and (N_CHANNELS-1 downto 0 => input_en);
	
-- Synchronous Logic
	-- 2-flop buffering of input signals
	process (CLK)
	begin
		if rising_edge (CLK) then
			pwm_p1 <= PWM_IN;
			pwm_p2 <= pwm_p1;
		end if;
	end process;	
	
-- Module Instances
FILTER_INSTS:
	for i in 0 to N_CHANNELS-1 generate
	begin
		filter_i: moving_avg_filter 
		GENERIC MAP (
			WINDOW_SZ => MAX_WINDOW,
		   NUM_WIDTH => NUM_WIDTH )		 
		PORT MAP(
			CLK => CLK,
			RST => RST,
			EN => EN,
			FILT_COEFF => filt_coeff,
			FILT_ORDER => filt_order, 
			INPUT => pwm_gated(i),
			OUTPUT => FILT_OUT((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH)
		);
	end generate;

	Inst_pwm_filt_block_regs: block_regs 
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

