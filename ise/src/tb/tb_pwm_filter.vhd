--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:12:57 09/17/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Emulator/Firmware/tb/tb_pwm_filter.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pwm_filter
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
 
ENTITY tb_pwm_filter IS
END tb_pwm_filter;
 
ARCHITECTURE behavior OF tb_pwm_filter IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 
		 constant N_CHANNELS : integer := 3;
		 constant NUM_WIDTH : integer := 16;
		 constant FW_DATA_WIDTH : integer := 32;
		 constant FW_ADDR_WIDTH : integer := 8;	
 
    COMPONENT pwm_filter
	 GENERIC ( 
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
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '1';
   signal EN : std_logic := '0';
   signal CS : std_logic := '0';
   signal WE : std_logic := '0';
   signal ADDR : std_logic_vector(FW_ADDR_WIDTH-1 downto 0) := (others => '0');
   signal DATA_I : std_logic_vector(FW_DATA_WIDTH-1 downto 0) := (others => '0');
   signal PWM_IN : std_logic_vector(N_CHANNELS-1 downto 0) := (others => '0');

 	--Outputs
   signal DATA_O : std_logic_vector(FW_DATA_WIDTH-1 downto 0);
   signal FILT_OUT : std_logic_vector(N_CHANNELS*NUM_WIDTH-1 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
	
	-- 
	signal we_1 : std_logic;
	signal addr_1 : std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
	signal data_1 : std_logic_vector(FW_DATA_WIDTH-1 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pwm_filter 
	GENERIC MAP (
			N_CHANNELS => N_CHANNELS,
			NUM_WIDTH => NUM_WIDTH,
			FW_DATA_WIDTH => FW_DATA_WIDTH,
			FW_ADDR_WIDTH => FW_ADDR_WIDTH ) 			
	PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => EN,
          CS => CS,
          WE => WE,
          ADDR => ADDR,
          DATA_I => DATA_I,
          DATA_O => DATA_O,
          PWM_IN => PWM_IN,
          FILT_OUT => FILT_OUT
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
		PWM_IN <= b"000";
		wait for CLK_period*10;
		PWM_IN <= b"001";
		wait for CLK_period*10;
		PWM_IN <= b"011";
		wait for CLK_period*10;
		PWM_IN <= b"111";
		wait for CLK_period*30;
		PWM_IN <= b"100";
		wait for CLK_period*40;
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
		
      wait for CLK_period*50;
		
		EN <= '1';
		
      wait for CLK_period*200;
		
		CS <= '1';
		
		addr_1 <= std_logic_vector(to_unsigned(0, FW_ADDR_WIDTH));
		data_1 <= x"00320c4b";			--filt_order=25, filt_coeff=24/(20*25)*2^15, input_en=1
		we_1 <= '1';
		wait for CLK_period;
		addr_1 <= (others => '0');
		data_1 <= (others => '0');
		we_1 <= '0';
		wait for CLK_period*3000;

      -- insert stimulus here 

      wait;
   end process;

END;
