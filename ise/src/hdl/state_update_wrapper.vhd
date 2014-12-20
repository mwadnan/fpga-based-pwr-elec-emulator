----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    12:49:23 07/25/2013 
-- Design Name: 
-- Module Name:    state_update_wrapper - Behavioral 
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
--			Definition of Generic Paaramter BITSHIFT_VEC
--				BITSHIFT is computed offline for each PE_i (corresponding to state X_i)
--				BITSHIFT is used to give maximum possible precision to the partial sums of Matrix multiplication
--				see example below
--	
--				x(k+1) = x(k) + (2^-BITSHIFT)*[ (2^BITSHIFT)*A*Ts*x(k) + (2^BITSHIFT)*B*Ts*x(k) ]
--
--				BITSHIFT_VEC is the combination of BITSHIFTs for each PE_i(state). 
--				Starting from LSB, 4-bits are used to define BITSHIFT for each PE_i.
--				e.g. In top.vhd, define BITSHIFT_VEC := conv_integer(x"52632");	(for N_X=5)
--					thus, BITSHIFT for PE_1=2; PE_2=3; PE_3=6; and so on...
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use work.regsize_calc.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity state_update_wrapper is
	Generic ( N_SLV_REGS : integer := 1;
				 BRAM_RD_ADDR_WIDTH : integer := 5;
				 -- Parameters above are NOT set in a higher hierarchy 
				 N_X	: integer := 4;
				 N_U  : integer := 3;
				 N_Z  : integer := 2;
				 BITSHIFT_VEC : integer := 0;
				 BRAM_WR_ADDR_WIDTH : integer := 6;
				 NUM_WIDTH : integer := 16;
				 FW_DATA_WIDTH : integer := 32;
				 FW_ADDR_WIDTH : integer := 8 
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
			  -- System Input (U) and Time Varying Parameter Input (Z)
           U_IN : in  STD_LOGIC_VECTOR (N_U*NUM_WIDTH-1 downto 0);
           Z_IN : in  STD_LOGIC_VECTOR (N_Z*NUM_WIDTH-1 downto 0);
			  -- State (X) output
           X_OUT : out  STD_LOGIC_VECTOR (N_X*NUM_WIDTH-1 downto 0)
			);
end state_update_wrapper;

architecture Behavioral of state_update_wrapper is

	constant SHORT_WIDTH : integer := FW_DATA_WIDTH/2;

	--constant BRAM_WR_ADDR_WIDTH : integer := BRAM_RD_ADDR_WIDTH + clog2((N_X*NUM_WIDTH)/FW_DATA_WIDTH);			--NOT VALID FOR (N_X*NUM_WIDTH) < FW_DATA_WIDTH
	
	constant BITSHIFT_VEC2 : std_logic_vector(4*N_X-1 downto 0) := std_logic_vector(to_unsigned(BITSHIFT_VEC, 4*N_X));
	
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

	COMPONENT coeff_ram
	  GENERIC ( WR_DATA_WIDTH 	: integer ;
					RD_ADDR_WIDTH 	: integer ;
					RD_DATA_WIDTH 	: integer ;
					WR_ADDR_WIDTH 	: integer );
	  PORT (
		 clka : IN STD_LOGIC;
		 wea : IN STD_LOGIC;
		 addra : IN STD_LOGIC_VECTOR(WR_ADDR_WIDTH-1 DOWNTO 0);
		 dina : IN STD_LOGIC_VECTOR(WR_DATA_WIDTH-1 DOWNTO 0);
		 clkb : IN STD_LOGIC;
		 addrb : IN STD_LOGIC_VECTOR(RD_ADDR_WIDTH-1 DOWNTO 0);
		 doutb : OUT STD_LOGIC_VECTOR(RD_DATA_WIDTH-1 DOWNTO 0)
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
	
	COMPONENT state_PE
	GENERIC ( 
			BITSHIFT : integer;
			PE_ID : integer;
			NUM_WIDTH : integer );
    PORT ( CLK : in  STD_LOGIC;
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
	END COMPONENT;
	
	COMPONENT state_update_SM
	GENERIC
		(	N_X : integer;
			N_U : integer;
			N_Z : integer;
			BRAM_RD_ADDR_WIDTH : integer );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		EN : IN std_logic;
		UPDATE_TRIG : IN std_logic;
		SOFT_RST : IN std_logic;  
		DONE	: OUT  std_logic;
	   U_REG_EN	: OUT  std_logic;
	   Z_REG_EN	: OUT  std_logic;
	   PE_IN_SEL : OUT  std_logic_vector(1 downto 0);
	   PE_OUT_SEL : OUT  std_logic_vector(1 downto 0);
		PE_MACC_RST : OUT std_logic;
		PE_MACC_SHIFT : OUT std_logic;
		BRAM_ADDR : OUT std_logic_vector(4 downto 0)
		);
	END COMPONENT;
	
	-- Control Register	
	signal block_regs_cs : std_logic;
	
	signal reg_data_i : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	signal reg_data_o : std_logic_vector(N_SLV_REGS*FW_DATA_WIDTH-1 downto 0);
	
	signal soft_rst 	: std_logic;
	signal update_en	: std_logic;
	signal period		: std_logic_vector(11 downto 0);
	
	signal calc_error : std_logic;
		
	--Interconnect
	signal update_trig : std_logic;
	signal done	: std_logic;
	
	signal u_reg_en : std_logic;
	signal U	: std_logic_vector(NUM_WIDTH-1 downto 0);
	
	signal z_reg_en : std_logic;
	signal Z : std_logic_vector(NUM_WIDTH-1 downto 0);
	
	signal x_in_comb	: std_logic_vector (N_X*NUM_WIDTH-1 downto 0);	
	signal reg_in_1_comb : std_logic_vector (N_X*NUM_WIDTH-1 downto 0);			-- Combined buses from each PE (to facilitate generic statements)
	signal reg_in_2_comb : std_logic_vector (N_X*NUM_WIDTH-1 downto 0);			-- Combined buses from each PE (to facilitate generic statements)
	
	signal x_out_comb	: std_logic_vector (N_X*NUM_WIDTH-1 downto 0);	
	signal reg_out_1_comb : std_logic_vector (N_X*NUM_WIDTH-1 downto 0);			-- Combined buses from each PE (to facilitate generic statements)
	signal reg_out_2_comb : std_logic_vector (N_X*NUM_WIDTH-1 downto 0);			-- Combined buses from each PE (to facilitate generic statements)
		
	signal bram_data 	: std_logic_vector(N_X*SHORT_WIDTH-1 downto 0);
	signal bram_addr	: std_logic_vector(BRAM_RD_ADDR_WIDTH-1 downto 0);
	
	signal bram_wea	: std_logic;	
	
	signal PE_in_sel : std_logic_vector(1 downto 0);
	signal PE_out_sel : std_logic_vector(1 downto 0);
	signal PE_macc_rst : std_logic;
	signal PE_macc_shift : std_logic;
	
begin
-- Block Registers are mapped on the 11th Addr Bit
-- (See register/bit mapping in Excel documentation)
	block_regs_cs <= CS and ADDR(10);
	bram_wea <= CS and WE and (not ADDR(10));	
	
-- Dissemination/Accumulation of Data to/from Block Registers 
-- (See register/bit mapping in Excel documentation)
	soft_rst 						<= reg_data_o(0);
	update_en 						<= reg_data_o(1);
	period 							<= reg_data_o(13 downto 2);
	
	reg_data_i(0) 					<= calc_error;
	reg_data_i(31 downto 1) 	<= (others => '0');
			
-- Data-Path Statements
SINGLE_STATE_CASE:
	if (N_X = 1) generate
	begin
		x_in_comb <= x_out_comb;
		reg_in_1_comb <= reg_out_1_comb;
		reg_in_2_comb <= reg_out_2_comb;	
	end generate;
	
MULTIPLE_STATE_CASE:
	if (N_X > 1) generate
	begin
		x_in_comb <= x_out_comb((N_X-1)*NUM_WIDTH-1 downto 0) & x_out_comb(N_X*NUM_WIDTH-1 downto (N_X-1)*NUM_WIDTH);
		reg_in_1_comb <= reg_out_1_comb((N_X-1)*NUM_WIDTH-1 downto 0) & reg_out_1_comb(N_X*NUM_WIDTH-1 downto (N_X-1)*NUM_WIDTH);
		reg_in_2_comb <= reg_out_2_comb((N_X-1)*NUM_WIDTH-1 downto 0) & reg_out_2_comb(N_X*NUM_WIDTH-1 downto (N_X-1)*NUM_WIDTH);	
	end generate;
		
	calc_error <= '0';
	
-- Synchronous Logic
	process (CLK)
	begin
		if rising_edge(CLK) then
			if (RST = '1') then
				X_OUT <= (others => '0');
			elsif (done = '1') then
				X_OUT <= x_out_comb;
			end if;
		end if;
	end process;	
	
-- Module Instances
	Inst_FSM: state_update_SM 
	GENERIC MAP (
			N_X => N_X,
			N_U => N_U,
			N_Z => N_Z,
			BRAM_RD_ADDR_WIDTH => BRAM_RD_ADDR_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		UPDATE_TRIG => update_trig,
		SOFT_RST => soft_rst,
		DONE => done,
		U_REG_EN => u_reg_en,
		Z_REG_EN => z_reg_en,
		PE_IN_SEL => PE_in_sel,
		PE_OUT_SEL => PE_out_sel,
		PE_MACC_RST => PE_macc_rst,
		PE_MACC_SHIFT => PE_macc_shift,
		BRAM_ADDR => bram_addr
	);

STATE_PE_INSTS:
   for i in 0 to N_X-1 generate
      begin
         PE_i: state_PE 
			GENERIC MAP( 
				BITSHIFT => conv_integer(BITSHIFT_VEC2((i+1)*4-1 downto i*4)),
				PE_ID => i,
				NUM_WIDTH => NUM_WIDTH )
			PORT MAP(
				CLK => CLK,
				RST => RST,
				IN_SEL => PE_in_sel,
				OUT_SEL => PE_out_sel,
				MACC_RST => PE_macc_rst,
				MACC_SHIFT => PE_macc_shift,
				U_IN => U,
				Z_IN => Z,
				COEFF_IN => bram_data((i+1)*SHORT_WIDTH-1 downto i*SHORT_WIDTH),-- & (NUM_WIDTH-SHORT_WIDTH-1 downto 0 => '0'),
				STATE_IN => x_in_comb((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH),
				REG_IN_1 => reg_in_1_comb((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH),
				REG_IN_2 => reg_in_2_comb((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH),
				STATE_OUT => x_out_comb((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH),
				REG_OUT_1 => reg_out_1_comb((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH),
				REG_OUT_2 => reg_out_2_comb((i+1)*NUM_WIDTH-1 downto i*NUM_WIDTH)
			);
   end generate;

	Inst_Uin: reg_serialize 
	GENERIC MAP ( N_REGS => N_U,
					  NUM_WIDTH => NUM_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		WE => update_trig,
		OE => u_reg_en,
		REG_IN => U_IN,
		DOUT => U
	);
	
	Inst_Zin: reg_serialize 
	GENERIC MAP ( N_REGS => N_Z,
					  NUM_WIDTH => NUM_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		WE => update_trig,
		OE => z_reg_en,
		REG_IN => Z_IN,
		DOUT => Z
	);
	
	Inst_trig_gen: trig_gen 
	GENERIC MAP ( CNT_WIDTH => 12 )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		EN => EN,
		TRIG_EN => update_en,
		PERIOD => period,
		TRIG_OUT => update_trig
	);
	
	Inst_ram: coeff_ram 
	GENERIC MAP ( WR_DATA_WIDTH => FW_DATA_WIDTH,
					RD_ADDR_WIDTH => BRAM_RD_ADDR_WIDTH,
					RD_DATA_WIDTH => N_X*SHORT_WIDTH,
					WR_ADDR_WIDTH => BRAM_WR_ADDR_WIDTH ) 
	 
	PORT MAP(
		clka => CLK,
		wea => bram_wea,
		addra => ADDR(BRAM_WR_ADDR_WIDTH+2-1 downto 2),		--lower 2 bits discarded - 32-bit data bus
		dina => DATA_I,
		clkb => CLK,
		addrb => bram_addr,
		doutb => bram_data
	);

	Inst_state_update_block_regs: block_regs 
	GENERIC MAP ( N_SLV_REGS => N_SLV_REGS,
						FW_ADDR_WIDTH => FW_ADDR_WIDTH,
						FW_DATA_WIDTH => FW_DATA_WIDTH )
	PORT MAP(
		CLK => CLK,
		RST => RST,
		CS => block_regs_cs,
		WE => WE,
		ADDR => ADDR,
		WB_DATA_I => DATA_I,
		WB_DATA_O => DATA_O,
		REG_DATA_I => reg_data_i,
		REG_DATA_O => reg_data_o
	);

end Behavioral;

