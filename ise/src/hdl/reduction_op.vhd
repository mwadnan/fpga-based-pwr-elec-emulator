--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package reduction_op is

	function and_reduce (arg : std_logic_vector) return std_logic;
	function or_reduce (arg : std_logic_vector) return std_logic;
	
end reduction_op;

package body reduction_op is

-- done in a recursively called function.
	function and_reduce (arg : std_logic_vector )
		return std_logic is
		variable Upper, Lower : std_logic;
		variable Half : integer;
		variable BUS_int : std_logic_vector ( arg'length - 1 downto 0 );
		variable Result : std_logic;
	begin
		if (arg'LENGTH < 1) then            -- In the case of a NULL range
			Result := '1';                    -- Change for version 1.3
		else
			BUS_int := to_ux01 (arg);
			if ( BUS_int'length = 1 ) then
				Result := BUS_int ( BUS_int'left );
			elsif ( BUS_int'length = 2 ) then
				Result := BUS_int ( BUS_int'right ) and BUS_int ( BUS_int'left );
			else
				Half := ( BUS_int'length + 1 ) / 2 + BUS_int'right;
				Upper := and_reduce ( BUS_int ( BUS_int'left downto Half ));
				Lower := and_reduce ( BUS_int ( Half - 1 downto BUS_int'right ));
				Result := Upper and Lower;
			end if;
		end if;
		return Result;
	end;

	function or_reduce (arg : std_logic_vector )
		return std_logic is
		variable Upper, Lower : std_logic;
		variable Half : integer;
		variable BUS_int : std_logic_vector ( arg'length - 1 downto 0 );
		variable Result : std_logic;
	begin
		if (arg'LENGTH < 1) then            -- In the case of a NULL range
			Result := '0';
		else
			BUS_int := to_ux01 (arg);
			if ( BUS_int'length = 1 ) then
				Result := BUS_int ( BUS_int'left );
			elsif ( BUS_int'length = 2 ) then
				Result := BUS_int ( BUS_int'right ) or BUS_int ( BUS_int'left );
			else
				Half := ( BUS_int'length + 1 ) / 2 + BUS_int'right;
				Upper := or_reduce ( BUS_int ( BUS_int'left downto Half ));
				Lower := or_reduce ( BUS_int ( Half - 1 downto BUS_int'right ));
				Result := Upper or Lower;
			end if;
		end if;
		return Result;
	end;
 
end reduction_op;
