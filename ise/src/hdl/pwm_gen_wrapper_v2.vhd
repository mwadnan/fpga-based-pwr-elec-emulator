----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    15:33:07 09/11/2013 
-- Design Name: 
-- Module Name:    pwm_gen_wrapper_v2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Gets Threshold values for SW_ON(rise) and SW_OFF(fall) instances, via the WISHBONE interface. Outputs a PWM Signal (one per channel) 
--
--			Also outputs a pulse at the end of each PERIOD, as specified in CONTROL register, in addition to Sawtooth/Triangle carrier waveform.
--			The pulse can, for example, be used to trigger an Interrupt on the CPU
--
-- Dependencies: 
--					Parameter MODE distinguishes between Sawtooth or Triangular waveform at the input
--					MODE = 1 => SAWTOOTH (SINGLE_FALLING_EDGE PWM)
--					MODE = 0 => TRIANGULAR (DOUBLE_EDGED/CENETERED PWM)
--
--					Parameter N_CHANNELS specifies the number of PWM channels/phases
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--		Assumption: CNT_WIDTH <= FW_DATA_WIDTH/2
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

entity pwm_gen_wrapper_v2 is
	 Generic ( CNT_WIDTH : integer := 16;
				  -- Parameters above are NOT set in a higher hierarchy
				  N_CHANNELS : integer := 3;
				  FW_ADDR_WIDTH : integer := 6;
				  FW_DATA_WIDTH : integer := 32 );
    Port ( CLK 	: in  STD_LOGIC;
           RST 	: in  STD_LOGIC;
           EN 		: in  STD_LOGIC;		  
			  -- WISHBONE Slave Signals 
			  CS				: in  STD_LOGIC;
			  WE			: in  STD_LOGIC;
			  ADDR		: in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
			  DATA_I		: in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  DATA_O		: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  -- Output
			  PERIOD_INTR	: out  STD_LOGIC;
			  PWM_EN 		: out  STD_LOGIC_VECTOR (N_CHANNELS-1 downto 0);
           PWM_OUT 		: out  STD_LOGIC_VECTOR (N_CHANNELS-1 downto 0)
			  );
end pwm_gen_wrapper_v2;

architecture Behavioral of pwm_gen_wrapper_v2 is

	CONSTANT N_SLV_REGS : integer := N_CHANNELS + 1;					-- REG 0 is for CONTROL information

	CONSTANT SHORT_WIDTH : integer := FW_DATA_WIDTH/2;

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
	
	COMPONENT pwm_gen_v2
	GENERIC ( CNT_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		EN : IN std_logic;
		PERIOD_TRIG : IN std_logic;
		SAWTOOTH : IN std_logic_vector(CNT_WIDTH-1 downto 0);
		RISE_THRESH : IN std_logic_vector(CNT_WIDTH-1 downto 0);
		FALL_THRESH : IN std_logic_vector(CNT_WIDTH-1 downto 0);          
		PWM_O : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT sawtooth_gen
	GENERIC ( CNT_WIDTH : integer );
    PORT ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  EN	: in  STD_LOGIC;
			  PERIOD : in  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
           COUNT_OUT : out  STD_LOGIC_VECTOR (CNT_WIDTH-1 downto 0);
			  PERIOD_TRIG : out STD_LOGIC );
	END COMPONENT;
	
	--Wishbone Slave Signals	
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	-- Control Signals
	signal intr_en			: std_logic;
	signal sw_en			: std_logic_vector (N_CHANNELS-1 downto 0);
	signal period			: std_logic_vector (CNT_WIDTH-1 downto 0);
	
	signal period_trig 	: std_logic;
	signal sawtooth_count : std_logic_vector(CNT_WIDTH-1 downto 0);
	
	signal rise_thresh : std_logic_vector(N_CHANNELS*CNT_WIDTH-1 downto 0);
	signal fall_thresh : std_logic_vector(N_CHANNELS*CNT_WIDTH-1 downto 0);
	
begin	

-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping in Excel documentation)
	intr_en <= reg_data_o(0);
	period <= reg_data_o(CNT_WIDTH downto 1);
	
	process (reg_data_o)
	begin
		for i in 1 to N_CHANNELS loop
			sw_en(i-1) <= reg_data_o(FW_DATA_WIDTH-i);
			rise_thresh(i*CNT_WIDTH-1 downto (i-1)*CNT_WIDTH) <= reg_data_o(i*FW_DATA_WIDTH+CNT_WIDTH-1 downto i*FW_DATA_WIDTH);
			fall_thresh(i*CNT_WIDTH-1 downto (i-1)*CNT_WIDTH) <= reg_data_o(i*FW_DATA_WIDTH+SHORT_WIDTH+CNT_WIDTH-1 downto i*FW_DATA_WIDTH+SHORT_WIDTH);
		end loop;
	end process;
	
	reg_data_i <= (others => '0');		-- zero initialized registers will be optimized out
	
-- DataPath Statements
	PWM_EN <= sw_en;

	PERIOD_INTR <= intr_en and period_trig;
	
-- Instantiations
PWM_GEN_INSTS:
   for i in 0 to N_CHANNELS-1 generate
      begin
         pwm_i: pwm_gen_v2 
			GENERIC MAP ( CNT_WIDTH => CNT_WIDTH )
			PORT MAP(
				CLK => CLK,
				EN => sw_en(i),
				PERIOD_TRIG => period_trig,
				SAWTOOTH => sawtooth_count,
				RISE_THRESH => rise_thresh((i+1)*CNT_WIDTH-1 downto i*CNT_WIDTH),
				FALL_THRESH => fall_thresh((i+1)*CNT_WIDTH-1 downto i*CNT_WIDTH),
				PWM_O => PWM_OUT(i)
			);
   end generate;
	
	Inst_sawtooth: sawtooth_gen 
	GENERIC MAP ( CNT_WIDTH => CNT_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		PERIOD => period,
		COUNT_OUT => sawtooth_count,
		PERIOD_TRIG => period_trig
	);

	--WISHBONE SLAVE INTERFACE	
	Inst_pwm_block_regs: block_regs 
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

