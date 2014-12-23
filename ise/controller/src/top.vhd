----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    17:40:37 04/25/2013 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Top Module for the Electrical Drive Controller Firmware (for Xilinx Spartan 6 LX9). 
--				- Instantiates 
--					* DCM for clock generation
--					* Lattice LM32 (opensource) processor 
--					* WISHBONE Bus architecture for Slave interfaces (Firmware Blocks)
--					* DDR Controller for interface to off-chip LPDDR Memory
--					* Firmware blocks for interfaces to PMOD I/O
--							* ADC Interface
--							* PWM Generator
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

use work.regsize_calc.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
	GENERIC ( N_WB_SLAVES 		: integer := 3;
				 FW_ADDR_WIDTH 	: integer := 12;
				 FW_DATA_WIDTH 	: integer := 32;
				 NUM_WIDTH			: integer := 16;
				 DDR_FRAME_SIZE	: integer := 4;
				 N_ADC_DEVICES		: integer := 1;
				 N_ADC_CHANNELS	: integer := 6;
				 N_PWM_CHANNELS	: integer := 3
				);
    Port ( 	CLK_IN 			: IN  STD_LOGIC;
				RST 				: IN  STD_LOGIC;
				UART_RX			: IN  STD_LOGIC;
				UART_TX			: OUT STD_LOGIC;
				GPIO_IN			: IN  STD_LOGIC_VECTOR(3 downto 0);
				GPIO_OUT 		: OUT STD_LOGIC_VECTOR(3 downto 0);
				-- PWM Signals
				PWM_OUT			: OUT  STD_LOGIC_VECTOR(N_PWM_CHANNELS-1 downto 0);
				PWM_EN			: OUT  STD_LOGIC_VECTOR(2 downto 0);
				-- SPI Signals
				ADC_SPI_CK		: OUT  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				ADC_SPI_SS_n	: OUT  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				ADC_SPI_MOSI	: OUT  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				ADC_SPI_MISO	: IN  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				-- LPDDR RAM Signals
				DRAM_DQ 			: INOUT std_logic_vector(15 downto 0);
				DRAM_DQS 		: INOUT std_logic;
				DRAM_UDQS 		: INOUT std_logic;
				DRAM_RZQ 		: INOUT std_logic; 
				DRAM_A 			: OUT std_logic_vector(12 downto 0);
				DRAM_BA 			: OUT std_logic_vector(1 downto 0);
				DRAM_CKE 		: OUT std_logic;
				DRAM_RAS_N 		: OUT std_logic;
				DRAM_CAS_N 		: OUT std_logic;
				DRAM_WE_N 		: OUT std_logic;
				DRAM_DM 			: OUT std_logic;
				DRAM_UDM 		: OUT std_logic;
				DRAM_CLK 		: OUT std_logic;
				DRAM_CLK_N 		: OUT std_logic
			  );
end top;

architecture Behavioral of top is

	component clk_gen
	port
	 (-- Clock in ports
	  CLK_IN1           : in     std_logic;
	  -- Clock out ports
	  CLK_OUT1          : out    std_logic;
	  CLK_OUT2          : out    std_logic;
	  -- Status and control signals
	  RESET             : in     std_logic;
	  LOCKED            : out    std_logic
	 );
	end component;

	COMPONENT wb_soc_v2
   PORT(
      clk_i   : in std_logic;
		reset_n : in std_logic;
		uartSIN : in std_logic;
		uartSOUT : out std_logic; 
		gpioPIO_BOTH_IN : in std_logic_vector(3 downto 0); 
		gpioPIO_BOTH_OUT : out std_logic_vector(3 downto 0); 
		slave_passthruclk : out std_logic; 
		slave_passthrurst : out std_logic; 
		slave_passthruslv_adr : out std_logic_vector(31 downto 0); 
		slave_passthruslv_master_data : out std_logic_vector(31 downto 0); 
		slave_passthruslv_slave_data : in std_logic_vector(31 downto 0); 
		slave_passthruslv_strb : out std_logic; 
		slave_passthruslv_cyc : out std_logic; 
		slave_passthruslv_ack : in std_logic; 
		slave_passthruslv_err : in std_logic; 
		slave_passthruslv_rty : in std_logic; 
		slave_passthruslv_sel : out std_logic_vector(3 downto 0); 
		slave_passthruslv_we : out std_logic; 
		slave_passthruslv_bte : out std_logic_vector(1 downto 0); 
		slave_passthruslv_cti : out std_logic_vector(2 downto 0); 
		slave_passthruslv_lock : out std_logic; 
		slave_passthruintr_active_high : in std_logic
      );
   END COMPONENT;
	
	COMPONENT wb_slave_interface_nosync
	GENERIC ( N_WB_SLAVES : integer; 
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer );
	PORT( CLK			: in  STD_LOGIC;
			 RST			: in  STD_LOGIC;
			 WB_DATA_I		: in  STD_LOGIC_VECTOR(31 downto 0);
			 WB_ADDR			: in  STD_LOGIC_VECTOR(31 downto 0);
			 WB_STRB			: in  STD_LOGIC;
			 WB_CYC			: in  STD_LOGIC;
			 WB_WE			: in  STD_LOGIC;
			 WB_ACK			: out STD_LOGIC;
			 WB_ERR			: out STD_LOGIC;
			 WB_RTY			: out STD_LOGIC;
			 WB_INTR			: out STD_LOGIC;
			 WB_DATA_O		: out  STD_LOGIC_VECTOR(31 downto 0);
			 FW_INTERRUPT  : in  STD_LOGIC;
			 FW_DOUT_COMB	: in  STD_LOGIC_VECTOR(FW_DATA_WIDTH*N_WB_SLAVES - 1 downto 0);
			 FW_CS 			: out  STD_LOGIC_VECTOR (N_WB_SLAVES-1 downto 0);
			 FW_WE 			: out  STD_LOGIC;
			 FW_DIN 			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			 FW_ADDR 		: out  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0)
			);
	END COMPONENT;
	
	COMPONENT ddr_ctrl_wrapper
	GENERIC ( FRAME_SIZE  : integer;
				 NUM_WIDTH : integer;
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer  );
    PORT ( CLK 			: in  STD_LOGIC;
           DDR_CLK 		: in  STD_LOGIC;
           RST 			: in  STD_LOGIC;
           EN 				: in  STD_LOGIC;
			  -- WISHBONE Slave Interface 
			  CS				: in  STD_LOGIC;
			  WE				: in  STD_LOGIC;
			  ADDR			: in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
			  DATA_I			: in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  DATA_O			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			  -- DATA INPUT for WR_FIFO 
			  WR_DATA_IN 	: in  STD_LOGIC_VECTOR (NUM_WIDTH*FRAME_SIZE-1 downto 0);
			  -- LPDDR Signals
			  DRAM_DQ 		: inout std_logic_vector(15 downto 0);
			  DRAM_DQS 		: inout std_logic;
			  DRAM_UDQS 	: inout std_logic;
			  DRAM_RZQ 		: inout std_logic; 
			  DRAM_A 		: out std_logic_vector(12 downto 0);
			  DRAM_BA 		: out std_logic_vector(1 downto 0);
			  DRAM_CKE 		: out std_logic;
			  DRAM_RAS_N 	: out std_logic;
			  DRAM_CAS_N 	: out std_logic;
			  DRAM_WE_N 	: out std_logic;
			  DRAM_DM 		: out std_logic;
			  DRAM_UDM 		: out std_logic;
			  DRAM_CLK 		: out std_logic;
			  DRAM_CLK_N 	: out std_logic
			 );
	END COMPONENT;
	
	COMPONENT adc_interface_wrapper
	GENERIC ( 
		N_DEVICES : integer;
		N_CHANNELS : integer;
		NUM_WIDTH : integer;
		FW_ADDR_WIDTH : integer;
		FW_DATA_WIDTH : integer
		);
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		CS : IN std_logic;
		WE : IN std_logic;
		ADDR : IN std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
		DATA_I : IN std_logic_vector(FW_DATA_WIDTH-1 downto 0);
		MISO : IN std_logic_vector(N_DEVICES-1 downto 0);          
		DATA_O : OUT std_logic_vector(FW_DATA_WIDTH-1 downto 0);
		SPI_CK : OUT std_logic_vector(N_DEVICES-1 downto 0);
		SPI_SS_n : OUT std_logic_vector(N_DEVICES-1 downto 0);
		MOSI : OUT std_logic_vector(N_DEVICES-1 downto 0);
		CHANNEL_OUT : OUT std_logic_vector (N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0)
		);
	END COMPONENT;
		
	COMPONENT pwm_gen_wrapper_v2
	GENERIC(
		N_CHANNELS : integer ;
		FW_ADDR_WIDTH : integer ;
		FW_DATA_WIDTH : integer  );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		CS : IN std_logic;
		WE : IN std_logic;
		ADDR : IN std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
		DATA_I : IN std_logic_vector(FW_DATA_WIDTH-1 downto 0);          
		DATA_O : OUT std_logic_vector(FW_DATA_WIDTH-1 downto 0);
		PERIOD_INTR : OUT std_logic;
		PWM_EN 		: OUT  STD_LOGIC;
		PWM_OUT : OUT std_logic_vector(N_CHANNELS-1 downto 0)
		);
	END COMPONENT;
	
	-- Infrastructure Signals 
	signal CLK				: std_logic;
	signal CPU_CLK			: std_logic;
	signal DDR_CLK			: std_logic;
	signal dcm_locked		: std_logic;
	
	-- CPU Signals
	signal cpu_reset_n 	: std_logic;
	
	attribute KEEP : string;
	attribute KEEP of CLK: signal is "TRUE";
	attribute KEEP of DDR_CLK: signal is "TRUE";
	
	-- WISHBONE Bus signals (Direction from Slave's perspective)
	signal WB_DATA_O		: std_logic_vector(31 downto 0);
	signal WB_ACK			: std_logic;
	signal WB_ERR			: std_logic;
	signal WB_RTY			: std_logic;
	signal WB_INTR			: std_logic;
	
	signal WB_DATA_I		: std_logic_vector(31 downto 0);
	signal WB_ADDR 		: std_logic_vector(31 downto 0);
	signal WB_STRB			: std_logic;
	signal WB_CYC			: std_logic;
	signal WB_WE			: std_logic;
	
	-- Signals for Interface between Firmware Blocks and WB SlavePassthru (Direction from Firmware Blocks' perspective)
	signal FW_CS			: std_logic_vector(N_WB_SLAVES-1 downto 0);
	signal FW_WE			: std_logic;
	signal FW_DIN			: std_logic_vector(FW_DATA_WIDTH-1 downto 0);
	signal FW_ADDR			: std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
	
	signal FW_INTERRUPT  : std_logic;
	signal FW_DOUT_COMB	: std_logic_vector(FW_DATA_WIDTH*N_WB_SLAVES - 1 downto 0);
	
	-- Firmware Blocks' Data Out Buses
	signal ddr_ctrl_dout		: std_logic_vector(FW_DATA_WIDTH-1 downto 0);
	signal adc_dout			: std_logic_vector(FW_DATA_WIDTH-1 downto 0);
	signal pwm_dout			: std_logic_vector(FW_DATA_WIDTH-1 downto 0);-- REMOVE
	
	-- Interconnect Between Firmware Blocks
	signal ddr_wr_trig 	: std_logic;
	signal ddr_frame 		: std_logic_vector (DDR_FRAME_SIZE*NUM_WIDTH-1 downto 0);
	
	signal adc_channel_out : std_logic_vector (N_ADC_DEVICES*N_ADC_CHANNELS*NUM_WIDTH-1 downto 0);
		
	signal pwm_en_sig  : std_logic;
	signal pwm_gen_out : std_logic_vector(N_PWM_CHANNELS-1 downto 0);
	
	signal pwm_intr_pulse : std_logic;	
		
begin

-- Combinational Logic
	cpu_reset_n <= not RST;
	
	PWM_EN <= pwm_en_sig & pwm_en_sig & pwm_en_sig;	
	PWM_OUT <= pwm_gen_out;

-- Interconnect between Firmware Blocks (See Excel File)
	-- DDR_FRAME - first value in MSB
	ddr_frame <= adc_channel_out(4*NUM_WIDTH-1 downto 0);				
		
-- Accumulation of Slave Data_O buses
	FW_DOUT_COMB <= pwm_dout & adc_dout & ddr_ctrl_dout;
	
	FW_INTERRUPT <= pwm_intr_pulse;

-- Module Instantiations
	-- Firmware blocks
	Inst_pwm_gen: pwm_gen_wrapper_v2
	GENERIC MAP ( N_CHANNELS => N_PWM_CHANNELS,
					FW_ADDR_WIDTH => FW_ADDR_WIDTH,
					FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => dcm_locked,
		CS => FW_CS(2),
		WE => FW_WE,
		ADDR => FW_ADDR,
		DATA_I => FW_DIN,
		DATA_O => pwm_dout,
		PERIOD_INTR => pwm_intr_pulse,
		PWM_EN => pwm_en_sig,
		PWM_OUT => pwm_gen_out
	);
	
	Inst_adc_interface: adc_interface_wrapper 
	GENERIC MAP ( N_DEVICES => N_ADC_DEVICES,
					 N_CHANNELS => N_ADC_CHANNELS,
					 NUM_WIDTH => NUM_WIDTH,
					 FW_ADDR_WIDTH => FW_ADDR_WIDTH,
					 FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => dcm_locked,
		CS => FW_CS(1),
		WE => FW_WE,
		ADDR => FW_ADDR,
		DATA_I => FW_DIN,
		DATA_O => adc_dout,
		SPI_CK => ADC_SPI_CK,
		SPI_SS_n => ADC_SPI_SS_n,
		MOSI => ADC_SPI_MOSI,
		MISO => ADC_SPI_MISO,
		CHANNEL_OUT => adc_channel_out
	);
	
	-- DDR Memory Controller + Internal Interface (Wishbone Slave)
	Inst_ddr: ddr_ctrl_wrapper 	
	GENERIC MAP( FRAME_SIZE  => DDR_FRAME_SIZE,
					NUM_WIDTH => NUM_WIDTH,
					FW_ADDR_WIDTH => FW_ADDR_WIDTH,
					FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		DDR_CLK => DDR_CLK,
		RST => RST,
		EN => dcm_locked,
		CS => FW_CS(0),
		WE => FW_WE,
		ADDR => FW_ADDR,
		DATA_I => FW_DIN,
		DATA_O => ddr_ctrl_dout,
		WR_DATA_IN => ddr_frame,
		DRAM_DQ => DRAM_DQ,
		DRAM_DQS => DRAM_DQS,
		DRAM_UDQS => DRAM_UDQS,
		DRAM_RZQ => DRAM_RZQ,
		DRAM_A => DRAM_A,
		DRAM_BA => DRAM_BA,
		DRAM_CKE => DRAM_CKE,
		DRAM_RAS_N => DRAM_RAS_N,
		DRAM_CAS_N => DRAM_CAS_N,
		DRAM_WE_N => DRAM_WE_N,
		DRAM_DM => DRAM_DM,
		DRAM_UDM => DRAM_UDM,
		DRAM_CLK => DRAM_CLK,
		DRAM_CLK_N => DRAM_CLK_N
	);

------------------------------------------------------------------------------
-- "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
-- "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
------------------------------------------------------------------------------
-- CLK_OUT1____66.671______0.000______50.0______200.000____150.000
-- CLK_OUT2___133.342______0.000______50.0______349.990____150.000
--
------------------------------------------------------------------------------
-- "Input Clock   Freq (MHz)    Input Jitter (UI)"
------------------------------------------------------------------------------
-- __primary__________66.667____________0.010

	CPU_CLK <= CLK;

	inst_dcm : clk_gen
	  port map
		(-- Clock in ports
		 CLK_IN1 => CLK_IN,
		 -- Clock out ports
		 CLK_OUT1 => CLK,				-- 66MHz
		 CLK_OUT2 => DDR_CLK,		-- 133MHz
		 -- Status and control signals
		 RESET  => RST,
		 LOCKED => dcm_locked);
	
	-- LM32 CPU + WISHBONE Interface	
	Inst_wb_slave_interface: wb_slave_interface_nosync 
	GENERIC MAP (  N_WB_SLAVES => N_WB_SLAVES, 
						FW_ADDR_WIDTH => FW_ADDR_WIDTH,
						FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		WB_DATA_I => WB_DATA_I,
		WB_ADDR => WB_ADDR,
		WB_STRB => WB_STRB,
		WB_CYC => WB_CYC,
		WB_WE => WB_WE,
		WB_ACK => WB_ACK,
		WB_ERR => WB_ERR,
		WB_RTY => WB_RTY,
		WB_INTR => WB_INTR,
		WB_DATA_O => WB_DATA_O,
		FW_INTERRUPT => FW_INTERRUPT,
		FW_DOUT_COMB => FW_DOUT_COMB,
		FW_CS => FW_CS,
		FW_WE => FW_WE,
		FW_DIN => FW_DIN,
		FW_ADDR => FW_ADDR
	);
		
	lm32_inst : wb_soc_v2
	PORT MAP (
		clk_i  => CPU_CLK,
		reset_n  => cpu_reset_n,
		uartSIN  => UART_RX,
		uartSOUT  => UART_TX,
		gpioPIO_BOTH_IN  => GPIO_IN,
		gpioPIO_BOTH_OUT  => GPIO_OUT,
		slave_passthruclk  => open,
		slave_passthrurst  => open,
		slave_passthruslv_adr  => WB_ADDR,
		slave_passthruslv_master_data  => WB_DATA_I,
		slave_passthruslv_slave_data  => WB_DATA_O,
		slave_passthruslv_strb  => WB_STRB,
		slave_passthruslv_cyc  => WB_CYC,
		slave_passthruslv_ack  => WB_ACK,
		slave_passthruslv_err  => WB_ERR,
		slave_passthruslv_rty  => WB_RTY,
		slave_passthruslv_sel  => open,
		slave_passthruslv_we  => WB_WE,
		slave_passthruslv_bte  => open,
		slave_passthruslv_cti  => open,
		slave_passthruslv_lock  => open,
		slave_passthruintr_active_high  => WB_INTR
	);

end Behavioral;

