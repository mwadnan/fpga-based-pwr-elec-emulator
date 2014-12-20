--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:09:36 09/03/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Emulator/Firmware/tb/tb_trig_gen.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: trig_gen
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
 
ENTITY tb_trig_gen IS
END tb_trig_gen;
 
ARCHITECTURE behavior OF tb_trig_gen IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT trig_gen
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         EN : IN  std_logic;
         TRIG_EN : IN  std_logic;
         PERIOD : IN  std_logic_vector(7 downto 0);
         TRIG_OUT : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '1';
   signal EN : std_logic := '0';
   signal TRIG_EN : std_logic := '0';
   signal PERIOD : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal TRIG_OUT : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: trig_gen PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => EN,
          TRIG_EN => TRIG_EN,
          PERIOD => PERIOD,
          TRIG_OUT => TRIG_OUT
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
		
		wait for CLK_period*100;
		PERIOD <= x"0E";
		
		TRIG_EN<= '1';
      -- insert stimulus here 

      wait;
   end process;

END;
