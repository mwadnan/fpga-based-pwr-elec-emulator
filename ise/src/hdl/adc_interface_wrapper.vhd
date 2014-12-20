----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:15:53 05/17/2013 
-- Design Name: 
-- Module Name:    adc_interface_wrapper - Behavioral 
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
-- 		2 Assumptions:
--				(N_DEVICES*N_CHANNELS) is even
--				 CHANNEL_WIDTH <= 16
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

entity adc_interface_wrapper is
	 Generic ( CHANNEL_WIDTH : integer := 12;
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
			  -- CHANNEL DATA OUTPUT (for DDR Dump)
			  CHANNEL_OUT 	: out STD_LOGIC_VECTOR (N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
			  -- SPI Interface
           SPI_CK 	: out  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
			  SPI_SS_n 	: out  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
           MOSI 		: out  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
           MISO 		: in  STD_LOGIC_VECTOR (N_DEVICES-1 downto 0)
			  );
end adc_interface_wrapper;

architecture Behavioral of adc_interface_wrapper is

	CONSTANT SHORT_WIDTH : integer := FW_DATA_WIDTH/2;

	CONSTANT N_SLV_REGS : integer := (N_DEVICES*N_CHANNELS)/2;	
	
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
	
	COMPONENT spi_master_sm
	GENERIC ( N_CHANNELS : integer; 
				CHANNEL_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		CE  : IN std_logic;
		TRIG : IN std_logic;
		MISO : IN std_logic;          
		MOSI : OUT std_logic;
		SPI_SS_n : OUT std_logic;
		REG_OUT : OUT std_logic_vector(N_CHANNELS*CHANNEL_WIDTH-1 downto 0)
		);
	END COMPONENT;
		
	-- Control Register		
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	signal adc_en	 		: std_logic;
	signal spi_clk_div	: std_logic_vector(7 downto 0);			
		
	-- Timing Signals
	signal spi_toggle		: std_logic;
	signal spi_ce			: std_logic;		-- Clock enable for SPI interface
	
	signal spi_clk			: std_logic;
	signal spi_clk_p1		: std_logic;
	
	--
	signal miso_p1 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	signal miso_p2 : STD_LOGIC_VECTOR (N_DEVICES-1 downto 0);
	
	signal channel_data : std_logic_vector (N_DEVICES*N_CHANNELS*CHANNEL_WIDTH-1 downto 0);
	
	signal sample_data : std_logic_vector (N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
		
begin
	
-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping in Excel documentation)
	adc_en 						<= reg_data_o(0);
	spi_clk_div 				<= reg_data_o(8 downto 1);
	
	process (sample_data)
	begin
		reg_data_i <= (others => '0');
		for i in 0 to N_SLV_REGS-1 loop			
			reg_data_i((i*FW_DATA_WIDTH)+SHORT_WIDTH-1 downto i*FW_DATA_WIDTH) <= channel_data((2*i+1)*CHANNEL_WIDTH-1 downto 2*i*CHANNEL_WIDTH) & 
																												(SHORT_WIDTH-CHANNEL_WIDTH-1 downto 0 => '0');
			reg_data_i((i+1)*FW_DATA_WIDTH-1 downto (i+1)*FW_DATA_WIDTH-SHORT_WIDTH) <= channel_data((2*i+2)*CHANNEL_WIDTH-1 downto (2*i+1)*CHANNEL_WIDTH) & 
																												 (SHORT_WIDTH-CHANNEL_WIDTH-1 downto 0 => '0');
		end loop;
	end process;
	
-- Datapath Statements
	SPI_CK <= (N_DEVICES-1 downto 0 => spi_clk);	
	
	CHANNEL_OUT <= sample_data;
	
	-- append zeros at the lower extra bits
	process (channel_data)
	begin
		sample_data <= (others => '0');
		for i in 0 to N_DEVICES*N_CHANNELS-1 loop
			sample_data((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH) <= channel_data((i+1)*CHANNEL_WIDTH-1 downto i*CHANNEL_WIDTH) &
																						(NUM_WIDTH-CHANNEL_WIDTH-1 downto 0 => '0');
		end loop;
	end process;

-- Combinational Logic
	spi_ce <= spi_clk and (not spi_clk_p1);
	
-- Synchronous logic
	process (CLK)
	begin
		if rising_edge (CLK) then
			if (RST = '1') then
				spi_clk <= '0';
			elsif (spi_toggle = '1') then
				spi_clk <= not spi_clk;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			spi_clk_p1 <= spi_clk;
		end if;
	end process;
	
	-- 2-flop buffering of input signals
	process (CLK)
	begin
		if rising_edge(CLK) then
			miso_p1 <= MISO;
		end if;
	end process;
	process (CLK)
	begin
		if rising_edge(CLK) then
			miso_p2 <= miso_p1;
		end if;
	end process;

-- Module Instantiations
	-- Instances of ADC Masters
	ADC_MASTER_INSTS:
   for i in 0 to N_DEVICES-1 generate
      begin	
			adc_master_i: spi_master_sm 
			GENERIC MAP ( N_CHANNELS => N_CHANNELS,
							  CHANNEL_WIDTH => CHANNEL_WIDTH )
			PORT MAP(
				CLK => CLK,
				RST => RST,
				CE => spi_ce,
				TRIG => adc_en,
				MISO => miso_p2(i),
				MOSI => MOSI(i),
				SPI_SS_n => SPI_SS_n(i),
				REG_OUT => channel_data(((i+1)*N_CHANNELS)*CHANNEL_WIDTH-1 downto (i*N_CHANNELS)*CHANNEL_WIDTH)
			);
	end generate;
	
	Inst_trig_gen: trig_gen 
	GENERIC MAP ( CNT_WIDTH => 8 )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		TRIG_EN => '1',
		PERIOD => spi_clk_div,
		TRIG_OUT => spi_toggle
	);
	
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

