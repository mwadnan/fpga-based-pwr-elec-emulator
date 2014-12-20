----------------------------------------------------------------------------------
-- Company: 	IFA, ETHZ
-- Engineer: 	MWA 
-- 
-- Create Date:    22:20:47 08/27/2013 
-- Design Name: 
-- Module Name:    wb_slave_interface_nosync - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--			Two main functions:
--				2. From WISHBONE bus's ADDRESS bus, generate Chip-selects (CS) and Register Addresses for individual FW Blocks
--				3. Multiplex DOUT busses from different Firmware blocks into the data bus.
--
--			Also forwards an interrupt pulse from firmware blocks to WISHBONE bus
--
--			As the name suggests, this block assumes same CLOCK for both WISHBONE bus and Firmware blocks. 
--			Thus, no synchronization mechanism is needed.
--			This interface allows slightly faster WB Read/Write Transactions
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_slave_interface_nosync is
	Generic ( N_WB_SLAVES : integer := 2; 
				 FW_ADDR_WIDTH : integer := 8;
				 FW_DATA_WIDTH : integer := 32);
	Port ( CLK			: in  STD_LOGIC;
			 RST			: in  STD_LOGIC;
			 -- Wishbone Bus Signals
			 WB_DATA_I		: in  STD_LOGIC_VECTOR(31 downto 0);
			 WB_ADDR			: in  STD_LOGIC_VECTOR(31 downto 0);
			 WB_STRB			: in  STD_LOGIC;
			 WB_CYC			: in  STD_LOGIC;
			 WB_WE			: in  STD_LOGIC;
			 WB_ACK			: out STD_LOGIC;
			 WB_ERR			: out STD_LOGIC;
			 WB_RTY			: out STD_LOGIC;
			 WB_INTR			: out STD_LOGIC;
			 WB_DATA_O		: out  STD_LOGIC_VECTOR(31 downto 0);
			 -- Firmware Blocks' Signals
			 FW_INTERRUPT	: in  STD_LOGIC;									-- Single cycle pulse
			 FW_DOUT_COMB	: in  STD_LOGIC_VECTOR(FW_DATA_WIDTH*N_WB_SLAVES - 1 downto 0);
			 FW_CS 			: out  STD_LOGIC_VECTOR (N_WB_SLAVES-1 downto 0);
			 FW_WE 			: out  STD_LOGIC;
			 FW_DIN 			: out  STD_LOGIC_VECTOR (FW_DATA_WIDTH-1 downto 0);
			 FW_ADDR 		: out  STD_LOGIC_VECTOR (FW_ADDR_WIDTH-1 downto 0)
			);
end wb_slave_interface;

architecture Behavioral of wb_slave_interface_nosync is

	constant WB_SLAVE_BASEADDR	: std_logic_vector(31 downto 0) := x"80000000";
	
	signal cs		: std_logic_vector (N_WB_SLAVES-1 downto 0);	
	
	signal strb		: std_logic;
	signal strb_p1	: std_logic;
	
	signal ack_cond : std_logic;
	signal ack_cond_p1 : std_logic;	
	signal ack_cond_p2 : std_logic;
	
	signal dout	: std_logic_vector (FW_DATA_WIDTH-1 downto 0);

begin

-- Datapath Statements
	WB_ERR <= '0';
	WB_RTY <= '0';
	WB_INTR <= FW_INTERRUPT;				-- may need to be extended over multiple cycles
	
	WB_ACK <= ack_cond and (not ack_cond_p1);					--posedge
	
	WB_DATA_O(FW_DATA_WIDTH-1 downto 0) <= dout;
	-- If data bus length on wishbone bus vs. firmware blocks is not the same
	DATA_I_UPPER: if (FW_DATA_WIDTH < 32) generate
	begin
		WB_DATA_O(31 downto FW_DATA_WIDTH) <= (31 downto FW_DATA_WIDTH => '0');
	end generate;
	
	FW_ADDR <= WB_ADDR (FW_ADDR_WIDTH-1 downto 0);
	FW_DIN <= WB_DATA_I (FW_DATA_WIDTH-1 downto 0);
	FW_CS <= cs;
	FW_WE <= WB_WE;
	
	process (strb, WB_ADDR)
	begin
		-- Chip-Selects and Register Addressing
		if ((strb = '1') and (WB_ADDR(31 downto 24) = WB_SLAVE_BASEADDR(31 downto 24))) then
			cs <= WB_ADDR (FW_ADDR_WIDTH+N_WB_SLAVES-1 downto FW_ADDR_WIDTH);
		else
			cs <= (others => '0');
		end if;
	end process;

-- Combinational Logic	
	strb <= WB_CYC and WB_STRB;
	ack_cond <= strb_p1;
	
	-- Slave Data MUX	
	WB_DATA_MUX: process (cs, FW_DOUT_COMB)
	begin
		dout <= (FW_DATA_WIDTH-1 downto 0 => '0');
		for i in 0 to N_WB_SLAVES-1 loop
			if (cs(i) = '1') then
				dout <= FW_DOUT_COMB((i+1)*FW_DATA_WIDTH-1 downto i*FW_DATA_WIDTH);
			end if;
		end loop;
	end process;
	
-- Sequential Logic (CPU_CLK Domain)	
	process (CLK)
	begin
		if rising_edge (CLK) then
			strb_p1 <= strb;
		
			ack_cond_p1 <= ack_cond;
			ack_cond_p2 <= ack_cond_p1;
			
			s1_dout <= dout;
		end if;
	end process;

end Behavioral;

