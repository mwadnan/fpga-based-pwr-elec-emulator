----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:30:30 05/17/2013 
-- Design Name: 
-- Module Name:    spi_master_sm - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--				Rate of the SPI interface depends on CE (SPI_CK is generated externally)
--				Generates the master signal (MOSI) and SPI_SS_n (chip enable)
--				Generates the channel address - for the next conversion frame - on MOSI, at posedge of SPI_CK
--				Latches and de-serializes the signal on MISO, at posedge of SPI_CK.
--				
--				Sampling rate determined by the signal TRIG. For every TRIG, the master cycles through all channels before returning to IDLE state.
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--		The period of the TRIG pulse, should be larger than Tsample_min = (N_CHANNELS*16 + 1)*Tspi_ck 
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


entity spi_master_sm is
	Generic (N_CHANNELS : integer := 4; 
				CHANNEL_WIDTH : integer := 12);
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  CE  : in  STD_LOGIC;
			  TRIG	: in  STD_LOGIC;
			  -- SPI Interface
           MISO : in  STD_LOGIC;
           MOSI : out  STD_LOGIC;
           SPI_SS_n : out  STD_LOGIC;
			  -- Output Values
			  REG_OUT : out  STD_LOGIC_VECTOR (N_CHANNELS*CHANNEL_WIDTH-1 downto 0) );
end spi_master_sm;

architecture Behavioral of spi_master_sm is

   type state_type is (	IDLE, SAMPLE_INIT, FRAME_START, FRAME_WAIT, SAMPLE_END ); 
	
   signal state, next_state : state_type; 		--Mealy State Machine
	
	signal dsr_i	: std_logic_vector (CHANNEL_WIDTH-1 downto 0);
	
	signal csr : std_logic_vector (15 downto 0);
	signal csr_d : std_logic;
	signal csr_q : std_logic;
	
	signal dsr_o	: std_logic_vector (3 downto 0);
	signal dsr_o_ld : std_logic;
	
	signal adc_channel : unsigned (2 downto 0);
	signal adc_channel_next : unsigned (2 downto 0);
	signal adc_channel_prev : unsigned (2 downto 0);
	signal adc_channel_inc : std_logic;
	signal adc_channel_lim : std_logic;
	
	signal reg_en : std_logic;
	
	signal data_in_comp : unsigned (CHANNEL_WIDTH-1 downto 0);
		
	
begin
	MOSI <= dsr_o(3);
	
	csr_q <= csr(14);
	
	adc_channel_next <= adc_channel + 1;
		
	STATE_TRANSITION: process (state, TRIG, csr_q)
	begin
		next_state <= state;		-- to avoid latches
		case (state) is
			when IDLE =>
				if (TRIG = '1') then
					next_state <= SAMPLE_INIT;
				end if;	
			when SAMPLE_INIT =>
				next_state <= FRAME_WAIT;
			when FRAME_START => 
				next_state <= FRAME_WAIT;
			when FRAME_WAIT =>
				if (csr_q = '1') then
					if (adc_channel_lim = '1') then
						next_state <= SAMPLE_END;
					else
						next_state <= FRAME_START;
					end if;
				end if;
			when SAMPLE_END =>
				next_state <= IDLE;
			when others =>
				next_state <= IDLE;
		end case;
	end process;

-- Arithmetic Operation
	-- Converting unsigned sample values to signed by removing offset
	data_in_comp <= unsigned(dsr_i) + ('1' & (CHANNEL_WIDTH-2 downto 0 => '0'));
	
-- State Machine Outputs
	SM_OUTPUTS: process (state)
	begin
		-- default values (to avoid latches)
		SPI_SS_n <= '0';
		dsr_o_ld <= '0';
		csr_d <= '0';
		adc_channel_inc <= '0';
		reg_en <= '0';
		
		case (state) is
			when IDLE =>
				SPI_SS_n <= '1';
			when SAMPLE_INIT =>
				dsr_o_ld <= '1';
				csr_d <= '1';
				adc_channel_inc <= '1';				
			when FRAME_START =>
				dsr_o_ld <= '1';
				csr_d <= '1';
				adc_channel_inc <= '1';
				reg_en <= '1';
			when FRAME_WAIT =>
				null;
			when SAMPLE_END =>
				reg_en <= '1';
			when others =>
				null;
		end case;
	end process;
	
	CHANNEL_LIM: process (adc_channel)
	begin
		if (adc_channel = to_unsigned(N_CHANNELS+1, 3)) then
			adc_channel_lim <= '1';
		else
			adc_channel_lim <= '0';
		end if;
	end process;
	
-- Sequential Logic
	ADC_CHANNEL_PROC: process (CLK)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				adc_channel <= (others => '0');	
				adc_channel_prev <= (others => '0');
			elsif ((CE = '1') and (adc_channel_inc = '1')) then
				adc_channel <= adc_channel_next;
				adc_channel_prev <= adc_channel;
			end if;
		end if;
	end process;
	
	-- Latching in the values at the end of SPI frame
	-- DEMUX based on adc_channel
	process (CLK)
	begin
		if rising_edge (CLK) then
			if ((CE = '1') and(reg_en = '1')) then
				for i in 0 to N_CHANNELS-1 loop
					if (adc_channel_prev =	to_unsigned(i, 3)) then
						REG_OUT((i+1)*CHANNEL_WIDTH-1 downto i*CHANNEL_WIDTH) <= std_logic_vector(data_in_comp);
					end if;
				end loop;
			end if;
		end if;
	end process;

	DATA_IN_SHIFT_REG: process (CLK)
	begin
		if rising_edge(CLK) then
			if (CE = '1') then
				dsr_i <= dsr_i(CHANNEL_WIDTH-2 downto 0) & MISO;
			end if;
		end if;
	end process;
	
	CONTROL_SHIFT_REG: process (CLK)
	begin
		if rising_edge(CLK) then
			if (CE = '1') then
				csr <= csr(14 downto 0) & csr_d;
			end if;
		end if;
	end process;	
	
	DATA_OUT_SHIFT_REG: process (CLK)
	begin
		if rising_edge(CLK) then
			if (CE = '1') then
				if (dsr_o_ld = '1') then
					dsr_o <= '0' & std_logic_vector(adc_channel_next);
				else
					dsr_o <= dsr_o(2 downto 0) & '0';
				end if;
			end if;
		end if;
	end process;
	
	STATE_UPDATE: process (CLK, RST)
	begin
		if RST = '1' then
			state <= IDLE;
		elsif rising_edge(CLK) then
			if (CE = '1') then
				state <= next_state;
			end if;
		end if;
	end process;

end Behavioral;

