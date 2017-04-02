/*
This file is part of fpgaNES.

fpgaNES is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

fpgaNES is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with fpgaNES.  If not, see <http://www.gnu.org/licenses/>.

from http://www.lothar-miller.de/s9y/categories/5-Entprellung
*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
	port
	(
		i_clk : in std_logic;
		i_in : in std_logic;
		o_q : out std_logic;
		o_riseedge : out std_logic;
		o_falledge : out std_logic
	);
end debounce;

architecture behavioral of debounce is
	signal s_prescaler : integer range 0 to 10239;
	signal s_shift_register : std_logic_vector(3 downto 0) := (others => '0');
begin
   process (i_clk)
	begin
		if rising_edge(i_clk) then
			o_riseedge <= '0';
			o_falledge <= '0';
				
			if s_prescaler = 0 then
				s_prescaler <= 10239;
				
				-- Pegel zuweisen
				if s_shift_register = "0000" then
					o_q <= '0';
				end if;

				if s_shift_register = "1111" then
					o_q <= '1';
				end if;

				-- steigende Flanke
				if s_shift_register = "0111" then
					o_riseedge <= '1';
				end if;
				
				-- fallende Flanke
				if s_shift_register = "1000" then
					o_falledge <= '1';
				end if;
				
				-- von rechts Eintakten
				s_shift_register <= s_shift_register(2 downto 0) & i_in;
			else
				s_prescaler <= s_prescaler - 1;
			end if;
		end if;
   end process;
end behavioral;
