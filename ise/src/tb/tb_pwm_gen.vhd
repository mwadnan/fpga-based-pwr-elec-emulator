--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:35:16 07/10/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Emulator/Firmware/tb/tb_pwm_gen.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pwm_gen_wrapper
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
--USE ieee.numeric_std.ALL;
 
ENTITY tb_pwm_gen IS
END tb_pwm_gen;
 
ARCHITECTURE behavior OF tb_pwm_gen IS 

	constant WIDTH : integer := 8;
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pwm_gen_wrapper
	 GENERIC ( NUM_WIDTH : integer := 16);
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         EN : IN  std_logic;
         CS : IN  std_logic;
         WB_WE : IN  std_logic;
         WB_ADDR : IN  std_logic_vector(5 downto 0);
         WB_DATA_I : IN  std_logic_vector(31 downto 0);
         WB_DATA_O : OUT  std_logic_vector(31 downto 0);
         REFERENCE : IN  std_logic_vector(3*NUM_WIDTH-1 downto 0);
         STRB : IN  std_logic;
         PWM_OUT : OUT  std_logic_vector(5 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '1';
   signal EN : std_logic := '0';
   signal CS : std_logic := '0';
   signal WB_WE : std_logic := '0';
   signal WB_ADDR : std_logic_vector(5 downto 0) := (others => '0');
   signal WB_DATA_I : std_logic_vector(31 downto 0) := (others => '0');
   signal REFERENCE : std_logic_vector(3*WIDTH-1 downto 0) := (others => '0');
   signal STRB : std_logic := '0';

 	--Outputs
   signal WB_DATA_O : std_logic_vector(31 downto 0);
   signal PWM_OUT : std_logic_vector(5 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pwm_gen_wrapper 
	GENERIC MAP (NUM_WIDTH => WIDTH)
	PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => EN,
          CS => CS,
          WB_WE => WB_WE,
          WB_ADDR => WB_ADDR,
          WB_DATA_I => WB_DATA_I,
          WB_DATA_O => WB_DATA_O,
          REFERENCE => REFERENCE,
          STRB => STRB,
          PWM_OUT => PWM_OUT
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
			
		RST <= '0';
      wait for CLK_period*10;
		EN <= '1';	
				
      wait for CLK_period*500;
		WB_DATA_I <= x"1F000000";
		CS <= '1';
		WB_WE <= '1';
		wait for CLK_PERIOD*2;		
		WB_WE <= '0';
		
		wait for CLK_period*500;
		
		WB_DATA_I <= x"1F000007";
		CS <= '1';
		WB_WE <= '1';
		wait for CLK_PERIOD*2;		
		WB_WE <= '0';
		
		wait for CLK_period*200;
			
		REFERENCE <= x"00130c";
		
		wait for CLK_period*50;
		
		REFERENCE <= x"1f0f00";
		
		-- insert stimulus here 

      wait;
   end process;

END;
