--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:07:28 06/25/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Emulator/Firmware/tb/tb_2ph_to_3ph.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: spacevector_2_3phase
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
 
ENTITY tb_2ph_to_3ph IS
END tb_2ph_to_3ph;
 
ARCHITECTURE behavior OF tb_2ph_to_3ph IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spacevector_2_3phase
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         TRIG : IN  std_logic;
         X_ALPHA : IN  std_logic_vector(15 downto 0);
         X_BETA : IN  std_logic_vector(15 downto 0);
         GAIN : IN  std_logic_vector(15 downto 0);
         X_1 : OUT  std_logic_vector(15 downto 0);
         X_2 : OUT  std_logic_vector(15 downto 0);
         X_3 : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '1';
   signal TRIG : std_logic := '0';
   signal X_ALPHA : std_logic_vector(15 downto 0) := (others => '0');
   signal X_BETA : std_logic_vector(15 downto 0) := (others => '0');
   signal GAIN : std_logic_vector(15 downto 0) := (others => '0');

 	--Outputs
   signal X_1 : std_logic_vector(15 downto 0);
   signal X_2 : std_logic_vector(15 downto 0);
   signal X_3 : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: spacevector_2_3phase PORT MAP (
          CLK => CLK,
          RST => RST,
          TRIG => TRIG,
          X_ALPHA => X_ALPHA,
          X_BETA => X_BETA,
          GAIN => GAIN,
          X_1 => X_1,
          X_2 => X_2,
          X_3 => X_3
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
      wait for 110 ns;	

		RST <= '0';
		
      wait for (CLK_period*10);
		wait for 1 ns;

		TRIG <= '1';
		X_ALPHA <= x"4000";			-- 0.5
		X_BETA <= x"C000";			-- -0.5
		GAIN <= x"8000";				-- -1
		
		wait for CLK_period;
		
		TRIG <= '0';
		
		wait for CLK_period*7;
		
		TRIG <= '1';
		X_ALPHA <= x"3cbb";			-- 0.4714
		X_BETA <= x"4e62";			-- 0.6124
		GAIN <= x"6883";				-- 0.8165
		
		wait for CLK_period;
		
		TRIG <= '0';
		
		

      -- insert stimulus here 

      wait;
   end process;

END;
