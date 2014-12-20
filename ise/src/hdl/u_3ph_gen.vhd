----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:13:43 09/02/2013 
-- Design Name: 
-- Module Name:    u_3ph_gen - Behavioral 
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
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity u_3ph_gen is
	Generic ( NUM_WIDTH : integer := 16 );
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           EN : in  STD_LOGIC;
           U_R_OUT : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           U_S_OUT : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0);
           U_T_OUT : out  STD_LOGIC_VECTOR (NUM_WIDTH-1 downto 0));
end u_3ph_gen;

architecture Behavioral of u_3ph_gen is

	CONSTANT PERIOD_VAL : integer := 102;			-- (166e6/8/(4096*50))

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
	
	COMPONENT reg_serialize
	GENERIC ( N_REGS : integer;
				 NUM_WIDTH : integer );	
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		WE : IN std_logic;
		OE : IN std_logic;
		REG_IN : IN std_logic_vector(N_REGS*NUM_WIDTH-1 downto 0);          
		DOUT : OUT std_logic_vector(NUM_WIDTH-1 downto 0)
		);
	END COMPONENT;

	COMPONENT dds_lut
		PORT (
		ce: in std_logic;
		clk: in std_logic;
		phase_in: in std_logic_vector(11 downto 0);
		cosine: out std_logic_vector(15 downto 0));
	end COMPONENT;
	
	signal period : std_logic_vector (7 downto 0);
		
	signal trig : std_logic;
	signal trig_pipe : std_logic_vector(8 downto 0);
	
	signal phase_in : std_logic_vector(11 downto 0);
	signal cosine : std_logic_vector(15 downto 0);
	
	signal phase_comb : std_logic_vector(35 downto 0);
	signal phase_oe : std_logic;
	
	signal phase_R : unsigned(11 downto 0);
	signal phase_S : unsigned(11 downto 0);
	signal phase_T : unsigned(11 downto 0);	
	
	signal phase_cnt : unsigned(11 downto 0);	
	
begin

	period <= std_logic_vector(to_unsigned(PERIOD_VAL, 8));
		
	phase_comb <= std_logic_vector(phase_R) & 
						std_logic_vector(phase_S) &
						std_logic_vector(phase_T) ;
						
	phase_oe <= trig_pipe(0) or trig_pipe(1);
	
	phase_R <= phase_cnt;
	phase_S <= phase_cnt + to_unsigned(2730, 12);		-- w*t + 4*pi/3 = w*t - 2*pi/3
	phase_T <= phase_cnt + to_unsigned(1365, 12);		-- w*t + 2*pi/3 = w*t - 4*pi/3
	
-- Synchronous Logic
	process (CLK) 
	begin
		if rising_edge(CLK) then
			if (trig_pipe(6) = '1') then
				U_R_OUT <= cosine;
			end if;
		end if;
	end process;
	process (CLK) 
	begin
		if rising_edge(CLK) then
			if (trig_pipe(7) = '1') then
				U_S_OUT <= cosine;
			end if;
		end if;
	end process;
	process (CLK) 
	begin
		if rising_edge(CLK) then
			if (trig_pipe(8) = '1') then
				U_T_OUT <= cosine;
			end if;
		end if;
	end process;

	process (CLK) 
	begin
		if rising_edge(CLK) then
			if (RST = '1') then
				phase_cnt <= (others => '0');
			elsif (trig = '1') then
				phase_cnt <= phase_cnt+1;
			end if;
		end if;
	end process;

	process (CLK) 
	begin
		if rising_edge (CLK) then
			trig_pipe <= trig_pipe(7 downto 0) & trig;
		end if;
	end process;

-- Module Instantiations
	inst_dds_lut : dds_lut
		PORT MAP (
			ce => '1',
			clk => CLK,
			phase_in => phase_in,
			cosine => cosine 
		);	
		
	Inst_phase_reg: reg_serialize 
	GENERIC MAP ( N_REGS => 3,
					  NUM_WIDTH => 12 )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		WE => trig,
		OE => phase_oe,
		REG_IN => phase_comb,
		DOUT => phase_in
	);

	Inst_trig_gen: trig_gen 
	GENERIC MAP ( CNT_WIDTH => 8 )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		TRIG_EN => '1',
		PERIOD => period,
		TRIG_OUT => trig
	);
	
end Behavioral;

