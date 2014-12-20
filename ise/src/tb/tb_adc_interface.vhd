--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:59:49 09/05/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Controller/Firmware/tb/tb_adc_interface.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: adc_interface_wrapper
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_adc_interface IS
END tb_adc_interface;
 
ARCHITECTURE behavior OF tb_adc_interface IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 
	 constant N_DEVICES : integer := 1;
	 constant N_CHANNELS : integer := 4;
	 constant NUM_WIDTH : integer := 16;
	 constant FW_ADDR_WIDTH : integer := 12;
	 constant FW_DATA_WIDTH : integer := 32;
				 
 
    COMPONENT adc_interface_wrapper
	 Generic ( N_DEVICES : integer;
				 N_CHANNELS : integer;
				 NUM_WIDTH : integer;
				 FW_ADDR_WIDTH : integer;
				 FW_DATA_WIDTH : integer
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
         CHANNEL_OUT : OUT  std_logic_vector(N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
         SPI_CK : OUT  std_logic_vector(N_DEVICES-1 downto 0);
         SPI_SS_n : OUT  std_logic_vector(N_DEVICES-1 downto 0);
         MOSI : OUT  std_logic_vector(N_DEVICES-1 downto 0);
         MISO : IN  std_logic_vector(N_DEVICES-1 downto 0)
        );
    END COMPONENT;
    
	COMPONENT adc_emulator_wrapper
	 Generic ( N_DEVICES : integer;
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
		CH_DATA_IN : IN std_logic_vector(N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
		SPI_CK : IN std_logic_vector(N_DEVICES-1 downto 0);
		SPI_SS_n : IN std_logic_vector(N_DEVICES-1 downto 0);
		MOSI : IN std_logic_vector(N_DEVICES-1 downto 0);          
		DATA_O : OUT std_logic_vector(FW_DATA_WIDTH-1 downto 0);
		MISO : OUT std_logic_vector(N_DEVICES-1 downto 0)
		);
	END COMPONENT;


   --Inputs
   signal CLK : std_logic := '0';
	signal CLK_slv	: std_logic := '0';
   signal RST : std_logic := '1';
   signal RST_slv : std_logic := '1';
   signal EN : std_logic := '0';
   signal CS : std_logic := '0';
   signal WE : std_logic := '0';
   signal ADDR : std_logic_vector(FW_ADDR_WIDTH-1 downto 0) := (others => '0');
   signal DATA_I : std_logic_vector(FW_DATA_WIDTH-1 downto 0) := (others => '0');
   signal CH_DATA_IN : std_logic_vector(N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0) := x"0123456789abcdef";

 	--Outputs
   signal DATA_O : std_logic_vector(FW_DATA_WIDTH-1 downto 0);
   signal CHANNEL_OUT : std_logic_vector(N_DEVICES*N_CHANNELS*NUM_WIDTH-1 downto 0);
	
	-- Interconnect
   signal MISO : std_logic_vector(N_DEVICES-1 downto 0);
   signal SPI_CK : std_logic_vector(N_DEVICES-1 downto 0);
   signal SPI_SS_n : std_logic_vector(N_DEVICES-1 downto 0);
   signal MOSI : std_logic_vector(N_DEVICES-1 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
   constant CLK_slv_period : time := 5 ns;
	
	-- 
	signal we_1 : std_logic;
	signal addr_1 : std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
	signal data_1 : std_logic_vector(FW_DATA_WIDTH-1 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adc_interface_wrapper 
	GENERIC MAP ( 
		N_DEVICES => N_DEVICES,
		N_CHANNELS => N_CHANNELS,
		NUM_WIDTH => NUM_WIDTH,
		FW_ADDR_WIDTH => FW_ADDR_WIDTH,
		FW_DATA_WIDTH => FW_DATA_WIDTH )				 
	PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => EN,
          CS => CS,
          WE => WE,
          ADDR => ADDR,
          DATA_I => DATA_I,
          DATA_O => DATA_O,
          CHANNEL_OUT => CHANNEL_OUT,
          SPI_CK => SPI_CK,
          SPI_SS_n => SPI_SS_n,
          MOSI => MOSI,
          MISO => MISO
        );
		  
	Inst_adc_emulator: adc_emulator_wrapper 
	GENERIC MAP ( 
		N_DEVICES => N_DEVICES,
		N_CHANNELS => N_CHANNELS,
		NUM_WIDTH => NUM_WIDTH,
		FW_ADDR_WIDTH => FW_ADDR_WIDTH,
		FW_DATA_WIDTH => FW_DATA_WIDTH )	
	PORT MAP(
		CLK => CLK_slv,
		RST => RST_slv,
		EN => EN,
		CS => CS,
		WE => WE,
		ADDR => ADDR,
		DATA_I => DATA_I,
		DATA_O => open,
		CH_DATA_IN => CH_DATA_IN,
		SPI_CK => SPI_CK,
		SPI_SS_n => SPI_SS_n,
		MOSI => MOSI,
		MISO => MISO
	);

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
	
   process
   begin
		CLK_slv <= '0';
		wait for CLK_slv_period/2;
		CLK_slv <= '1';
		wait for CLK_slv_period/2;
   end process;
	
	process (CLK)
	begin
		if rising_edge(CLK) then
			WE <= we_1;
			ADDR <= addr_1;
			DATA_I <= data_1;
		end if;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;
			RST <= '0';

      wait for CLK_period*10;
		EN <= '1';
		
		
      wait for CLK_period*100;
      -- insert stimulus here
		CS <= '1';
		
		addr_1 <= std_logic_vector(to_unsigned(0, FW_ADDR_WIDTH));
		data_1 <= x"00000007";			--clkdiv=3, adc_en=1
		we_1 <= '1';
		wait for CLK_period;
		addr_1 <= (others => '0');
		data_1 <= (others => '0');
		we_1 <= '0';
		wait for CLK_period*3000;
		
		RST_slv <= '0';
		
--		CH_DATA_IN <= x"0472094729472353";
--		
--		wait for CLK_period*700;
--				
--		CH_DATA_IN <= x"0472027224623353";
--		
--		wait for CLK_period*1200;
--				
--		CH_DATA_IN <= x"04a0272b46c2fe53";

      wait;
   end process;

END;
