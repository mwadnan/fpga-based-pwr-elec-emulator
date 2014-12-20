----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA
-- 
-- Create Date:    12:02:45 07/25/2013 
-- Design Name: 
-- Module Name:    state_PE - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--				Processing element (PE) for a single state variable 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--				BITSHIFT is computed offline for each PE_i (corresponding to state X_i)
--				BITSHIFT is used to give maximum possible precision to the partial sums of Matrix multiplication
--				see example below
--	
--				x(k+1) = x(k) + (2^-BITSHIFT)*[ (2^BITSHIFT)*A*Ts*x(k) + (2^BITSHIFT)*B*Ts*x(k) ]			
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity state_PE is
	Generic ( BITSHIFT : integer := 1;
				 PE_ID : integer := 0;
				 NUM_WIDTH : integer := 16 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  IN_SEL : in  STD_LOGIC_VECTOR(1 downto 0);
			  OUT_SEL : in  STD_LOGIC_VECTOR(1 downto 0);
			  MACC_RST : in  STD_LOGIC;
			  MACC_SHIFT : in  STD_LOGIC;
			  U_IN : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           Z_IN : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           COEFF_IN : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
			  STATE_IN : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           REG_IN_1 : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           REG_IN_2 : in  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
			  STATE_OUT : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           REG_OUT_1 : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           REG_OUT_2 : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0) 
			  );
end state_PE;

architecture Behavioral of state_PE is

	COMPONENT signed_mult
	GENERIC ( NUM_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		A : IN std_logic_vector(NUM_WIDTH-1 downto 0);
		B : IN std_logic_vector(NUM_WIDTH-1 downto 0);          
		P : OUT std_logic_vector(NUM_WIDTH-1 downto 0)
		);
	END COMPONENT;

	signal state_reg	: std_logic_vector (3*NUM_WIDTH-1 downto 0);
	signal reg_1		: std_logic_vector (3*NUM_WIDTH-1 downto 0);
	signal reg_2		: std_logic_vector (3*NUM_WIDTH-1 downto 0);
	
	signal macc_in_1 :	std_logic_vector (NUM_WIDTH-1 downto 0);
	signal macc_in_2 :	std_logic_vector (NUM_WIDTH-1 downto 0);
	
	signal macc_ld		: std_logic;
	signal macc_ld_data :  std_logic_vector (2*NUM_WIDTH-1 downto 0);

	signal macc_out_ovf : std_logic;
	signal macc_out_raw : std_logic_vector (2*NUM_WIDTH-1 downto 0);
   signal macc_out : std_logic_vector (NUM_WIDTH-1 downto 0);
		
begin
	STATE_OUT <= state_reg(3*NUM_WIDTH-1 downto 2*NUM_WIDTH);
	REG_OUT_1 <= reg_1(3*NUM_WIDTH-1 downto 2*NUM_WIDTH);
	REG_OUT_2 <= reg_2(3*NUM_WIDTH-1 downto 2*NUM_WIDTH);

-- Combinational Logic	

	macc_in_1 <= reg_1(3*NUM_WIDTH-1 downto 2*NUM_WIDTH);
	macc_in_2 <= COEFF_IN;
	
	macc_ld <= MACC_RST or MACC_SHIFT or macc_out_ovf;
	
	process (MACC_RST, MACC_SHIFT, macc_out_raw)
	begin
		if (MACC_RST = '1') then
			macc_ld_data <= (others => '0');					-- MACC_RST overrides the overflow condition
		elsif (MACC_SHIFT = '1') then
			macc_ld_data <= (2*NUM_WIDTH-1 downto 2*NUM_WIDTH-BITSHIFT => macc_out_raw(2*NUM_WIDTH-1)) & 			
									macc_out_raw(2*NUM_WIDTH-1 downto BITSHIFT);						-- Shifting result right by BITSHIFT bits
		else
			macc_ld_data <= macc_out_raw(2*NUM_WIDTH-1) & macc_out_raw(2*NUM_WIDTH-1) &
								(2*NUM_WIDTH-3 downto 0 => macc_out_raw(2*NUM_WIDTH-2));		-- positive or negative max;
		end if;
	end process;		
		
	-- Overflow check + Saturation
	macc_out_ovf <= macc_out_raw(2*NUM_WIDTH-1) xor macc_out_raw(2*NUM_WIDTH-2);	
	
	process (macc_out_raw, macc_out_ovf)
	begin
		if (macc_out_ovf = '1') then
			macc_out <= macc_out_raw(2*NUM_WIDTH-1) & (NUM_WIDTH-2 downto 0 => macc_out_raw(2*NUM_WIDTH-2));		-- positive or negative max
		else
			macc_out <= macc_out_raw(2*NUM_WIDTH-2 downto NUM_WIDTH-1);		-- discarding extra sign bit due to signed multiplication
		end if;
	end process;
		
-- Sequential Logic
	process (CLK)
	begin
		if rising_edge (CLK) then
			case (IN_SEL) is
				when b"00" =>
					reg_1(NUM_WIDTH-1 downto 0) <= state_reg(2*NUM_WIDTH-1 downto NUM_WIDTH);
				when b"01" =>
					reg_1(NUM_WIDTH-1 downto 0) <= U_IN;
				when b"10" =>
					reg_1(NUM_WIDTH-1 downto 0) <= REG_IN_1;
				when b"11" =>
					reg_1(NUM_WIDTH-1 downto 0) <= REG_IN_2;
				when others =>
					reg_1(NUM_WIDTH-1 downto 0) <= state_reg(2*NUM_WIDTH-1 downto NUM_WIDTH);
			end case;
			reg_1(3*NUM_WIDTH-1 downto NUM_WIDTH) <= reg_1(2*NUM_WIDTH-1 downto 0);
		end if;
	end process;	
	
	process (CLK)
	begin
		if rising_edge (CLK) then
			case (OUT_SEL) is
				when b"00" =>
					null;					-- hold previous value
				when b"01" =>
					state_reg(NUM_WIDTH-1 downto 0) <= COEFF_IN;
				when b"10" =>
					state_reg(NUM_WIDTH-1 downto 0) <= macc_out;
				when b"11" =>
					state_reg(NUM_WIDTH-1 downto 0) <= STATE_IN;
				when others =>
					null;
			end case;
			state_reg(3*NUM_WIDTH-1 downto NUM_WIDTH) <= state_reg(2*NUM_WIDTH-1 downto 0);
		end if;
	end process;
	
	NO_Z_MULT: if (not(PE_ID = 0)) generate
	begin
		process (CLK)
		begin
			if rising_edge(CLK) then
				reg_2 <= reg_2(2*NUM_WIDTH-1 downto 0) & REG_IN_2;
			end if;
		end process;
	end generate;
	
-- Multiply-Accumulate Macro		
	Z_MULT: if (PE_ID = 0) generate
	begin	
		Inst_Z_mult: signed_mult 
		GENERIC MAP ( NUM_WIDTH => NUM_WIDTH )
		PORT MAP(
			CLK => CLK,
			RST => RST,
			A => STATE_IN,
			B => Z_IN,
			P => reg_2(3*NUM_WIDTH-1 downto 2*NUM_WIDTH) 
		);		
	end generate;	
	
	MACC_inst : MACC_MACRO
		generic map (
			DEVICE => "SPARTAN6",  		-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			LATENCY => 3,         		-- Desired clock cycle latency, 1-4
			WIDTH_A => NUM_WIDTH,      -- Multiplier A-input bus width, 1-25
			WIDTH_B => NUM_WIDTH,      -- Multiplier B-input bus width, 1-18     
			WIDTH_P => 2*NUM_WIDTH)    -- Accumulator output bus width, 1-48
		port map (
			P => macc_out_raw,     					-- MACC ouput bus, width determined by WIDTH_P generic 
			A => macc_in_1,     						-- MACC input A bus, width determined by WIDTH_A generic 
			ADDSUB => '1', 						-- 1-bit add/sub input, high selects add, low selects subtract
			B => macc_in_2,           				-- MACC input B bus, width determined by WIDTH_B generic 
			CARRYIN => '0', 						-- 1-bit carry-in input to accumulator
			CE => '1',      						-- 1-bit active high input clock enable
			CLK => CLK,    						-- 1-bit positive edge clock input
			LOAD => macc_ld, 							-- 1-bit active high input load accumulator enable
			LOAD_DATA => macc_ld_data, 	-- Load accumulator input data, width determined by WIDTH_P generic
			RST => RST   						 	-- 1-bit input active high reset
		);

end Behavioral;

