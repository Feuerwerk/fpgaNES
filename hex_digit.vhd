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
*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity hex_digit is
	port
	(
		i_d : in std_logic_vector(3 downto 0);
		o_q : out std_logic_vector(6 downto 0)
	);
end hex_digit;

architecture behavioral of hex_digit is
	signal s_q: std_logic_vector(6 downto 0);
begin
	
	process (i_d)
	begin
		case i_d is
			when "0000" => -- 0
				s_q <= "0111111";
			
			when "0001" => -- 1
				s_q <= "0000110";
				
			when "0010" => -- 2
				s_q <= "1011011";
				
			when "0011" => -- 3
				s_q <= "1001111";
				
			when "0100" => -- 4
				s_q <= "1100110";
				
			when "0101" => -- 5
				s_q <= "1101101";
				
			when "0110" => -- 6
				s_q <= "1111101";
				
			when "0111" => -- 7
				s_q <= "0000111";
				
			when "1000" => -- 8
				s_q <= "1111111";
				
			when "1001" => -- 9
				s_q <= "1101111";
				
			when "1010" => -- A
				s_q <= "1110111";
				
			when "1011" => -- B
				s_q <= "1111100";
				
			when "1100" => -- C
				s_q <= "0111001";
				
			when "1101" => -- D
				s_q <= "1011110";
				
			when "1110" => -- E
				s_q <= "1111001";
				
			when "1111" => -- F
				s_q <= "1110001";
				
			when others =>
				s_q <= "0000000";

			end case;
	end process;
	
	o_q <= not s_q;

end architecture;