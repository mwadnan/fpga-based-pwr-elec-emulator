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
--			Top Module for the Electrical Drive Emulator Firmware (for Xilinx Spartan 6 LX9). 
--				- Instantiates 
--					* DCM for clock generation
--					* Lattice LM32 (opensource) processor 
--					* WISHBONE Bus architecture for Slave interfaces (Firmware Blocks)
--					* DDR Controller for interface to off-chip LPDDR Memory
--					* Firmware blocks for calculation and interfaces to PMOD I/O
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

use work.regsize_calc.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
	GENERIC ( N_WB_SLAVES 		: integer := 5;
				 FW_ADDR_WIDTH 	: integer := 12;
				 FW_DATA_WIDTH 	: integer := 32;
				 NUM_WIDTH			: integer := 18;
				 DDR_FRAME_SIZE	: integer := 4;
				 N_ADC_DEVICES		: integer := 1;
				 N_ADC_CHANNELS	: integer := 5;
				 N_PWM_CHANNELS	: integer := 3
				);
    Port ( 	CLK_IN 			: IN  STD_LOGIC;
				RST 				: IN  STD_LOGIC;
				UART_RX			: IN  STD_LOGIC;
				UART_TX			: OUT STD_LOGIC;
				GPIO_IN			: IN  STD_LOGIC_VECTOR(3 downto 0);
				GPIO_OUT 		: OUT STD_LOGIC_VECTOR(3 downto 0);
				-- PWM Signals
				PWM_IN			: IN  STD_LOGIC_VECTOR(N_PWM_CHANNELS-1 downto 0);
				-- SPI Signals
				ADC_SPI_CK		: IN  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				ADC_SPI_SS_n	: IN  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				ADC_SPI_MOSI	: IN  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
				ADC_SPI_MISO	: OUT  STD_LOGIC_VECTOR (N_ADC_DEVICES-1 downto 0);
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

	CONSTANT SHORT_WIDTH : integer := FW_DATA_WIDTH/2;

	component clk_gen
	port
	 (-- Clock in ports
	  CLK_IN1           : in     std_logic;
	  -- Clock out ports
	  CPU_CLK          : out    std_logic;
	  SYS_CLK          : out    std_logic;
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
	
	COMPONENT wb_slave_interface
	GENERIC ( N_WB_SLAVES : integer; 
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer );
	PORT( CLK			: in  STD_LOGIC;
			 CPU_CLK		: in  STD_LOGIC;
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
			 FW_INTERRUPT	: in  STD_LOGIC;
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
	
	COMPONENT adc_emulator_wrapper
	GENERIC ( N_DEVICES : integer;
				 N_CHANNELS : integer;
				 NUM_WIDTH : integer;
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer
				 );
	PORT ( CLK 		: in  STD_LOGIC;
		  RST 		: in  STD_LOGIC;
		  EN 			: in  STD_LOGIC; 
		  CS				: in  STD_LOGIC;
		  WE				: in  STD_LOGIC;
		  ADDR			: in  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0);
		  DATA_I			: in  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
		  DATA_O			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
		  CH_DATA_IN	: in  STD_LOGIC_VECTOR (N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
		  SPI_CK 	: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
		  SPI_SS_n 	: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
		  MOSI 		: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
		  MISO 		: out  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0)
		  );
	END COMPONENT;
	
	COMPONENT cpu_calc_wrapper
	GENERIC (
		N_SLV_REGS : integer;
		N_IN_VALS : integer;
		N_OUT_VALS : integer;
		NUM_WIDTH : integer;
		FW_DATA_WIDTH : integer;
		FW_ADDR_WIDTH : integer 
		);
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		CS : IN std_logic;
		WE : IN std_logic;
	   ADDR : in  std_logic_vector (FW_ADDR_WIDTH-1 downto 0);
	   DATA_I : in  std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	   DATA_O : out  std_logic_vector (FW_DATA_WIDTH-1 downto 0);
	   INTR_OUT : out std_logic;
	   NUM_IN : in  std_logic_vector (N_IN_VALS*NUM_WIDTH-1 downto 0);
	   NUM_OUT : out  std_logic_vector (N_OUT_VALS*NUM_WIDTH-1 downto 0)
		);
	END COMPONENT;
	
	COMPONENT pwm_filter
	GENERIC ( 
			WINDOW_SZ : integer;
			N_CHANNELS : integer;
			NUM_WIDTH : integer;
			FW_DATA_WIDTH : integer;
			FW_ADDR_WIDTH : integer 
			);	
   PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         EN : IN  std_logic;
         CS : IN  std_logic;
         WE : IN  std_logic;
         ADDR : IN  std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
         DATA_I : IN  std_logic_vector(FW_DATA_WIDTH-1 downto 0);
         DATA_O : OUT  std_logic_vector(FW_DATA_WIDTH-1 downto 0);
         PWM_IN : IN  std_logic_vector(N_CHANNELS-1 downto 0);
         FILT_OUT : OUT  std_logic_vector(N_CHANNELS*NUM_WIDTH-1 downto 0)
        );
    END COMPONENT;
	
	COMPONENT state_update_wrapper
	GENERIC ( N_X	: integer;
				 N_U  : integer;
				 N_Z  : integer;
				 BITSHIFT_VEC : integer;
				 BRAM_WR_ADDR_WIDTH : integer;
				 NUM_WIDTH : integer;
				 FW_DATA_WIDTH : integer;
				 FW_ADDR_WIDTH : integer 
				 );
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         EN : IN  std_logic;
         CS : IN  std_logic;
         WE : IN  std_logic;
         ADDR : IN  std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
         DATA_I : IN  std_logic_vector(FW_DATA_WIDTH-1 downto 0);
         DATA_O : OUT  std_logic_vector(FW_DATA_WIDTH-1 downto 0);
         U_IN : IN  std_logic_vector(N_U*NUM_WIDTH-1 downto 0);
         Z_IN : IN  std_logic_vector(N_Z*NUM_WIDTH-1 downto 0);
         X_OUT : OUT  std_logic_vector(N_X*NUM_WIDTH-1 downto 0)
        );
    END COMPONENT;
	 
	COMPONENT u_3ph_gen
	GENERIC ( NUM_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;          
		U_R_OUT : OUT std_logic_vector(NUM_WIDTH-1 downto 0);
		U_S_OUT : OUT std_logic_vector(NUM_WIDTH-1 downto 0);
		U_T_OUT : OUT std_logic_vector(NUM_WIDTH-1 downto 0)
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
	
	signal FW_INTR			: std_logic;
	signal FW_DOUT_COMB	: std_logic_vector(FW_DATA_WIDTH*N_WB_SLAVES - 1 downto 0);
	
	-- Firmware Blocks' Data Out Buses
	signal ddr_ctrl_dout		: std_logic_vector(FW_DATA_WIDTH-1 downto 0);
	signal adc_dout			: std_logic_vector(FW_DATA_WIDTH-1 downto 0);
	signal cpu_calc_dout		: std_logic_vector(FW_DATA_WIDTH-1 downto 0);
	signal pwm_filt_dout		: std_logic_vector(FW_DATA_WIDTH-1 downto 0);	
	signal s1_dout				: std_logic_vector(FW_DATA_WIDTH-1 downto 0);	
	
	signal cpu_calc_intr 	: std_logic;			-- Interrupt Pulse
	
	-- Interconnect Between Firmware Blocks
	signal ddr_wr_trig 	: std_logic;
	signal ddr_frame 		: std_logic_vector (DDR_FRAME_SIZE*NUM_WIDTH-1 downto 0);
	
	signal adc_channel_din	: std_logic_vector (N_ADC_DEVICES*N_ADC_CHANNELS*NUM_WIDTH-1 downto 0);
	
	-- CPU Calculation Block (for generic Non-linear calculations)
	constant CPU_CALC_N_SLVS 	: integer := 2;			-- should be (1 + ceil(max(N_IN, N_OUT)/2))
	constant CPU_CALC_N_IN 		: integer := 1;
	constant CPU_CALC_N_OUT 	: integer := 2;
	
	signal cpu_calc_in		: std_logic_vector (CPU_CALC_N_IN*SHORT_WIDTH-1 downto 0);
	signal cpu_calc_out		: std_logic_vector (CPU_CALC_N_OUT*SHORT_WIDTH-1 downto 0);
	
	-- PWM Filter Block (Moving average filter for input PWM Signal)
	constant PWM_FILT_WINDOW_SZ 		: integer := 40;
	
	signal pwm_filt_out		: std_logic_vector(N_PWM_CHANNELS*SHORT_WIDTH-1 downto 0);
	
	-- State Update S1
	constant S1_N_X 						: integer := 4;
	constant S1_N_U 						: integer := 4;
	constant S1_N_Z 						: integer := 1;
	constant S1_BITSHIFT_VEC 			: integer := conv_integer(x"4aaa");
	constant S1_BRAM_WR_ADDR_WIDTH 	: integer := 6;		-- => (5 + log2((s1_N_X*NUM_WIDTH)/FW_DATA_WIDTH));
			
	signal s1_u_in : std_logic_vector(S1_N_U*NUM_WIDTH-1 downto 0);
	signal s1_z_in : std_logic_vector(S1_N_Z*NUM_WIDTH-1 downto 0);
	
	signal s1_x_out : std_logic_vector(S1_N_X*NUM_WIDTH-1 downto 0);
	
	-- 
	signal udc_val : std_logic_vector(NUM_WIDTH-1 downto 0);
	signal R_L_inv : std_logic_vector(NUM_WIDTH-1 downto 0);
	signal i_L_val : std_logic_vector(NUM_WIDTH-1 downto 0);
	
begin

-- Combinational Logic
	cpu_reset_n <= not RST;
	
-- Interconnect between Firmware Blocks (See Excel File)
	-- DDR_FRAME - first value in MSB
	ddr_frame <= s1_x_out(NUM_WIDTH-1 downto 0) &
						s1_x_out(2*NUM_WIDTH-1 downto NUM_WIDTH) &
						s1_x_out(3*NUM_WIDTH-1 downto 2*NUM_WIDTH) &
						s1_x_out(4*NUM_WIDTH-1 downto 3*NUM_WIDTH);
		
	-- ADC_CHANNEL_DATA - first value in LSB
	adc_channel_din <= s1_x_out & udc_val;
	
	-- CPU_CALC_IN - first value in LSB
	cpu_calc_in <= (others => '0');
	
	R_L_inv <= cpu_calc_out(SHORT_WIDTH-1 downto 0) & (NUM_WIDTH-SHORT_WIDTH-1 downto 0 => '0');
	i_L_val <= cpu_calc_out(2*SHORT_WIDTH-1 downto SHORT_WIDTH) & (NUM_WIDTH-SHORT_WIDTH-1 downto 0 => '0');
			
	-- Input Vector - First value in MSB
	s1_u_in <=  pwm_filt_out(SHORT_WIDTH-1 downto 0) & (NUM_WIDTH-SHORT_WIDTH-1 downto 0 => '0') & 
					pwm_filt_out(2*SHORT_WIDTH-1 downto SHORT_WIDTH) & (NUM_WIDTH-SHORT_WIDTH-1 downto 0 => '0') & 
					pwm_filt_out(3*SHORT_WIDTH-1 downto 2*SHORT_WIDTH) & (NUM_WIDTH-SHORT_WIDTH-1 downto 0 => '0') &
					i_L_val;	
	
	s1_z_in <= R_L_inv;
			
-- Accumulation of Slave Data_O buses
	FW_DOUT_COMB <= s1_dout & pwm_filt_dout & cpu_calc_dout & adc_dout & ddr_ctrl_dout;
	
	FW_INTR <= '0';

-- Module Instantiations
	-- Firmware blocks	  
	Inst_state_update_S1: state_update_wrapper 
	GENERIC MAP (
				 N_X	=> S1_N_X,
				 N_U  => S1_N_U,
				 N_Z  => S1_N_Z,
				 BITSHIFT_VEC => S1_BITSHIFT_VEC,
				 BRAM_WR_ADDR_WIDTH => S1_BRAM_WR_ADDR_WIDTH,
				 NUM_WIDTH => NUM_WIDTH,
				 FW_DATA_WIDTH => FW_DATA_WIDTH,
				 FW_ADDR_WIDTH => FW_ADDR_WIDTH )
	PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => dcm_locked,
          CS => FW_CS(4),
          WE => FW_WE,
          ADDR => FW_ADDR,
          DATA_I => FW_DIN,
          DATA_O => s1_dout,
          U_IN => s1_u_in,
          Z_IN => s1_z_in,
          X_OUT => s1_x_out
        );
		  
--	Inst_u_3ph_gen: u_3ph_gen 
--	GENERIC MAP ( NUM_WIDTH => NUM_WIDTH )
--	PORT MAP(
--		CLK => CLK,
--		RST => RST,
--		EN => dcm_locked,
--		U_R_OUT => u_R,
--		U_S_OUT => u_S,
--		U_T_OUT => u_T 
--	);

   Inst_pwm_filter: pwm_filter 
	GENERIC MAP (
			WINDOW_SZ => PWM_FILT_WINDOW_SZ,
			N_CHANNELS => N_PWM_CHANNELS,
			NUM_WIDTH => SHORT_WIDTH,
			FW_DATA_WIDTH => FW_DATA_WIDTH,
			FW_ADDR_WIDTH => FW_ADDR_WIDTH ) 			
	PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => dcm_locked,
          CS => FW_CS(3),
          WE => FW_WE,
          ADDR => FW_ADDR,
          DATA_I => FW_DIN,
          DATA_O => pwm_filt_dout,
          PWM_IN => PWM_IN,
          FILT_OUT => pwm_filt_out
        );

	Inst_cpu_calc: cpu_calc_wrapper 
	GENERIC MAP (
		N_SLV_REGS => CPU_CALC_N_SLVS,
		N_IN_VALS => CPU_CALC_N_IN,
		N_OUT_VALS => CPU_CALC_N_OUT,
		NUM_WIDTH => SHORT_WIDTH,
		FW_DATA_WIDTH => FW_DATA_WIDTH,
		FW_ADDR_WIDTH => FW_ADDR_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => dcm_locked,
		CS => FW_CS(2),
		WE => FW_WE,
		ADDR => FW_ADDR,
		DATA_I => FW_DIN,
		DATA_O => cpu_calc_dout,
		INTR_OUT => cpu_calc_intr,
		NUM_IN => cpu_calc_in,
		NUM_OUT => cpu_calc_out 
	);

	Inst_adc_emulator: adc_emulator_wrapper 
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
		CH_DATA_IN => adc_channel_din,
		SPI_CK => ADC_SPI_CK,
		SPI_SS_n => ADC_SPI_SS_n,
		MOSI => ADC_SPI_MOSI,
		MISO => ADC_SPI_MISO 
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
-- CLK_OUT2___200.013______0.000______50.0______299.993____150.000
--
------------------------------------------------------------------------------
-- "Input Clock   Freq (MHz)    Input Jitter (UI)"
------------------------------------------------------------------------------
-- __primary__________66.667____________0.010

	DDR_CLK <= CLK;

	inst_dcm : clk_gen
	  port map
		(-- Clock in ports
		 CLK_IN1 => CLK_IN,
		 -- Clock out ports
		 CPU_CLK => CPU_CLK,		-- 66MHz
		 SYS_CLK => CLK,			-- 200MHz
		 -- Status and control signals
		 RESET  => RST,
		 LOCKED => dcm_locked);
	
	-- LM32 CPU + WISHBONE Interface	
	Inst_wb_slave_interface: wb_slave_interface 
	GENERIC MAP (  N_WB_SLAVES => N_WB_SLAVES, 
						FW_ADDR_WIDTH => FW_ADDR_WIDTH,
						FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		CPU_CLK => CPU_CLK,
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
		FW_INTERRUPT => FW_INTR,
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

