--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:51:45 09/02/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Emulator/Firmware/tb/tb_u3ph_gen.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: u_3ph_gen
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
 
ENTITY tb_u3ph_gen IS
END tb_u3ph_gen;
 
ARCHITECTURE behavior OF tb_u3ph_gen IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT u_3ph_gen
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         EN : IN  std_logic;
         U_R_OUT : OUT  std_logic_vector(15 downto 0);
         U_S_OUT : OUT  std_logic_vector(15 downto 0);
         U_T_OUT : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '1';
   signal EN : std_logic := '0';

 	--Outputs
   signal U_R_OUT : std_logic_vector(15 downto 0);
   signal U_S_OUT : std_logic_vector(15 downto 0);
   signal U_T_OUT : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: u_3ph_gen PORT MAP (
          CLK => CLK,
          RST => RST,
          EN => EN,
          U_R_OUT => U_R_OUT,
          U_S_OUT => U_S_OUT,
          U_T_OUT => U_T_OUT
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
      -- insert stimulus here 

      wait;
   end process;

END;
