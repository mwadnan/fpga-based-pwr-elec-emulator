--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:55:04 08/10/2013
-- Design Name:   
-- Module Name:   Y:/private/ProjectFiles/EDrive_Emulator/Firmware/tb/tb_state_update.vhd
-- Project Name:  Firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: state_update_wrapper
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

use IEEE.STD_LOGIC_UNSIGNED.ALL;

library std;
use std.textio.all;
 
ENTITY tb_state_update IS
END tb_state_update;
 
ARCHITECTURE behavior OF tb_state_update IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 
				 constant BRAM_RD_ADDR_WIDTH : integer := 5;
				 constant N_X	: integer := 4;
				 constant N_U  : integer := 3;
				 constant N_Z  : integer := 1;
				 constant BRAM_WR_ADDR_WIDTH : integer := 6;
				 constant NUM_WIDTH : integer := 18;
				 constant FW_DATA_WIDTH : integer := 32;
				 constant FW_ADDR_WIDTH : integer := 12 ;
				 constant BITSHIFT : integer := conv_integer(x"8855");
	 
 
   COMPONENT state_update_wrapper
	Generic ( BRAM_RD_ADDR_WIDTH : integer;
				 N_X	: integer;
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
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '0';
   signal EN : std_logic := '0';
   signal CS : std_logic := '0';
   signal WE : std_logic := '0';
   signal ADDR : std_logic_vector(FW_ADDR_WIDTH-1 downto 0) := (others => '0');
   signal DATA_I : std_logic_vector(FW_DATA_WIDTH-1 downto 0) := (others => '0');
   signal U_IN : std_logic_vector(N_U*NUM_WIDTH-1 downto 0) := (others => '0');
   signal Z_IN : std_logic_vector(N_Z*NUM_WIDTH-1 downto 0) := (others => '0');

 	--Outputs
   signal DATA_O : std_logic_vector(FW_DATA_WIDTH-1 downto 0);
   signal X_OUT : std_logic_vector(N_X*NUM_WIDTH-1 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
	
	-- 
	signal we_1 : std_logic;
	signal addr_1 : std_logic_vector(FW_ADDR_WIDTH-1 downto 0);
	signal data_1 : std_logic_vector(FW_DATA_WIDTH-1 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: state_update_wrapper 
	GENERIC MAP (
				BRAM_RD_ADDR_WIDTH => BRAM_RD_ADDR_WIDTH,
				 N_X	=> N_X,
				 N_U  => N_U,
				 N_Z  => N_Z,
				 BITSHIFT_VEC => BITSHIFT,
				 BRAM_WR_ADDR_WIDTH => BRAM_WR_ADDR_WIDTH,
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
          U_IN => U_IN,
          Z_IN => Z_IN,
          X_OUT => X_OUT
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
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
		variable addr_2 : integer := -4;
		
		file fptr : text;
		file fptr_w : text;
		variable inline : line;
		variable outline : line;
		
		variable rdData_1 : integer;
		variable rdData_2 : integer;
		
		variable wrData : integer;
   begin		
		RST <= '1';
		
		-- Write zero to initialize Block Memory 
		we_1 <= '0';
		CS <= '1';
		addr_1 <= (others => '0');
		data_1 <= (others => '0');
		for i in 0 to 15 loop
			addr_2 := addr_2 + 4;
			addr_1 <= std_logic_vector(to_unsigned(addr_2, FW_ADDR_WIDTH));
			we_1 <= '1';
			wait for CLK_period;
			we_1 <= '0';
			wait for CLK_period;
		end loop;
		CS <= '0';
		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		RST <= '0';
		
      wait for CLK_period*10;
		
		EN <= '1';
		
		wait for CLK_period*10;
		
		CS <= '1';
		addr_2 := -4;	
		
		-- Writing Contents of Block Memory
		file_open(fptr, "tb\coeff_file.txt", READ_MODE);
		while (not endfile(fptr)) loop
			readline (fptr, inline);
			read(inline, rdData_1);
			readline (fptr, inline);
			read(inline, rdData_2);
			
			addr_2 := addr_2 + 4;
			addr_1 <= std_logic_vector(to_unsigned(addr_2, FW_ADDR_WIDTH));
			data_1 <= std_logic_vector(to_signed(rdData_2, NUM_WIDTH) & to_signed(rdData_1, NUM_WIDTH));
			we_1 <= '1';
			wait for CLK_period;
			addr_1 <= (others => '0');
			data_1 <= (others => '0');
			we_1 <= '0';
			wait for CLK_period;
		end loop;
		file_close(fptr);
		
		wait for CLK_period*10;
		
		-- Control Register
		addr_2 := 256*4;
		addr_1 <= std_logic_vector(to_unsigned(addr_2, FW_ADDR_WIDTH));
		data_1 <= x"00000020";		--period = 5
		we_1 <= '1';
		wait for CLK_period;
		addr_1 <= (others => '0');
		data_1 <= (others => '0');
		we_1 <= '0';
		wait for CLK_period*100;
		
		addr_2 := 256*4;
		addr_1 <= std_logic_vector(to_unsigned(addr_2, FW_ADDR_WIDTH));
		data_1 <= x"00000022";			--period=5; update_en=1
		we_1 <= '1';
		wait for CLK_period;
		addr_1 <= (others => '0');
		data_1 <= (others => '0');
		we_1 <= '0';
		wait for 5*CLK_period;
		
      -- Writing TestVectors (from file) to the inputs
		file_open(fptr, "tb\test_vec.txt", READ_MODE);
		file_open(fptr_w, "tb\out_vec.txt", WRITE_MODE);
		while (not endfile(fptr)) loop
			readline (fptr, inline);
			read(inline, rdData_1);			
			U_IN(3*NUM_WIDTH-1 downto 2*NUM_WIDTH) <= std_logic_vector(to_signed(rdData_1, NUM_WIDTH));
			readline (fptr, inline);
			read(inline, rdData_1);			
			U_IN(2*NUM_WIDTH-1 downto NUM_WIDTH) <= std_logic_vector(to_signed(rdData_1, NUM_WIDTH));
			readline (fptr, inline);
			read(inline, rdData_1);			
			U_IN(NUM_WIDTH-1 downto 0) <= std_logic_vector(to_signed(rdData_1, NUM_WIDTH));
			readline (fptr, inline);
			read(inline, rdData_1);	
			Z_IN <= std_logic_vector(to_signed(rdData_1, NUM_WIDTH));
					
			wait for 4*8*CLK_period;
			
			wrData := to_integer(signed(X_OUT(NUM_WIDTH-1 downto 0)));
			write(outline, wrData);
			writeline(fptr_w, outline);
			wrData := to_integer(signed(X_OUT(2*NUM_WIDTH-1 downto NUM_WIDTH)));
			write(outline, wrData);
			writeline(fptr_w, outline);
			wrData := to_integer(signed(X_OUT(3*NUM_WIDTH-1 downto 2*NUM_WIDTH)));
			write(outline, wrData);
			writeline(fptr_w, outline);
			wrData := to_integer(signed(X_OUT(4*NUM_WIDTH-1 downto 3*NUM_WIDTH)));
			write(outline, wrData);
			writeline(fptr_w, outline);
			
		end loop;
		file_close(fptr);
		file_close(fptr_w);

      wait;
   end process;

END;
