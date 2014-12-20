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

use IEEE.NUMERIC_STD.ALL;

package regsize_calc is

	function clog2 (value : integer) return integer;
	
end regsize_calc;

package body regsize_calc is

	function clog2 (value : integer) return integer is
		variable temp : integer := 0;
		variable i : integer := 0;
   begin    
      while (temp < value) loop
			temp := to_integer(to_unsigned(1, 32) rol i);
			i := i + 1;
		end loop;
		return i-1;
   end clog2;
 
end regsize_calc;

