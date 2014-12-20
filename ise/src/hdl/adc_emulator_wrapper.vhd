----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    13:27:47 05/17/2013 
-- Design Name: 
-- Module Name:    adc_emulator_wrapper - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--						ADC Emulator - Behaves like an multi-channel ADC device, with an SPI Interface. 
--						The ADC devices will act as SPI Slaves, with the SPI_CLK as an input.
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--		Although the design is kept generic, it follows the behaviour of AD converters ADCXXYS051Q by TI
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

entity adc_emulator_wrapper is
	Generic ( N_SLV_REGS : integer := 1;
				 CHANNEL_WIDTH : integer := 12;
				 -- Parameters above are NOT set in a higher hierarchy 
				 N_DEVICES : integer := 2;
				 N_CHANNELS : integer := 10;
				 NUM_WIDTH : integer := 16;
				 FW_ADDR_WIDTH : integer := 8;
				 FW_DATA_WIDTH : integer := 32
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
			  -- Data Input for ADC Channels
			  CH_DATA_IN	: in  STD_LOGIC_VECTOR (N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
			  -- SPI Interface
           SPI_CK 	: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
			  SPI_SS_n 	: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
           MOSI 		: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
           MISO 		: out  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0)
			  );
end adc_emulator_wrapper;

architecture Behavioral of adc_emulator_wrapper is

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

	COMPONENT spi_slave_sm
	GENERIC (N_CHANNELS : integer; 
				CHANNEL_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		REG_IN : IN std_logic_vector(N_CHANNELS*CHANNEL_WIDTH-1 downto 0);
		SPI_CK : IN std_logic;
		SPI_SS_n : IN std_logic;
		MOSI : IN std_logic;          
		MISO : OUT std_logic
		);
	END COMPONENT;
	
	-- Control Register	
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	--
	signal spi_ck_p1 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	signal spi_ck_p2 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	signal spi_ss_p1 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	signal spi_ss_p2 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	signal mosi_p1 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	signal mosi_p2 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	
	signal ch_data : std_logic_vector (N_DEVICES*N_CHANNELS*CHANNEL_WIDTH-1 downto 0);

begin

-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping idasdn Excel documentation)
	reg_data_i <= (others => '0');
	
-- Dataflow 

WIDTH_CASE_1:	
	if (CHANNEL_WIDTH > NUM_WIDTH) generate
	begin
		process (CH_DATA_IN)
		begin
			for i in 0 to N_DEVICES-1 loop
				for j in 0 to N_CHANNELS-1 loop
					ch_data(((i*N_CHANNELS + j)+1)*CHANNEL_WIDTH-1 downto (i*N_CHANNELS + j)*CHANNEL_WIDTH+NUM_WIDTH) <= 
													(((i*N_CHANNELS + j)+1)*CHANNEL_WIDTH-1 downto (i*N_CHANNELS + j)*CHANNEL_WIDTH+NUM_WIDTH => '0');		
													
					ch_data((i*N_CHANNELS + j)*CHANNEL_WIDTH+NUM_WIDTH-1 downto (i*N_CHANNELS + j)*CHANNEL_WIDTH) <= 
													CH_DATA_IN(((i*N_CHANNELS + j)+1)*NUM_WIDTH-1 downto (i*N_CHANNELS + j)*NUM_WIDTH);
				end loop;
			end loop;
		end process;
	end generate;
	
WIDTH_CASE_2:	
	if (CHANNEL_WIDTH <= NUM_WIDTH) generate
	begin
		process (CH_DATA_IN)
		begin
			for i in 0 to N_DEVICES-1 loop
				for j in 0 to N_CHANNELS-1 loop
					ch_data(((i*N_CHANNELS + j)+1)*CHANNEL_WIDTH-1 downto (i*N_CHANNELS + j)*CHANNEL_WIDTH) <= 
													CH_DATA_IN(((i*N_CHANNELS + j)+1)*NUM_WIDTH-1 downto ((i*N_CHANNELS + j)+1)*NUM_WIDTH-CHANNEL_WIDTH);
				end loop;
			end loop;
		end process;
	end generate;
	
-- Synchronous logic
	-- 2-flop buffering of input signals
	process (CLK)
	begin
		if rising_edge(CLK) then
			spi_ck_p1 <= SPI_CK;
			spi_ss_p1 <= SPI_SS_n;
			mosi_p1 <= MOSI;
		end if;
	end process;
	process (CLK)
	begin
		if rising_edge(CLK) then
			spi_ck_p2 <= spi_ck_p1;
			spi_ss_p2 <= spi_ss_p1;
			mosi_p2 <= mosi_p1;
		end if;
	end process;
	
-- Instances of ADC Devices
ADC_DEV_INSTS:
   for i in 0 to N_DEVICES-1 generate
      begin	
			adc_i: spi_slave_sm 
			GENERIC MAP ( N_CHANNELS => N_CHANNELS,
							  CHANNEL_WIDTH => CHANNEL_WIDTH )
			PORT MAP(
				CLK => CLK,
				RST => RST,
				REG_IN => ch_data(((i+1)*N_CHANNELS)*CHANNEL_WIDTH-1 downto (i*N_CHANNELS)*CHANNEL_WIDTH),
				SPI_CK => spi_ck_p2(i),
				SPI_SS_n => spi_ss_p2(i),
				MOSI => mosi_p2(i),
				MISO => MISO(i)
			);
	end generate;
	
	Inst_adc_block_regs: block_regs 
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

