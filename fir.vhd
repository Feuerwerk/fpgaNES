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

-- @todo currently not working

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity high_pass_fir is
	generic
	(
		CONST : std_logic_vector(15 downto 0)
	);
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic;
		i_reset_n : in std_logic := '1';
		i_data : in std_logic_vector(15 downto 0);
		o_q : out std_logic_vector(15 downto 0)
	);
end high_pass_fir;

architecture behavioral of high_pass_fir is
	signal s_in_d : std_logic_vector(15 downto 0) := x"0000";
	signal s_out : std_logic_vector(15 downto 0) := x"0000";
	signal s_out_d : std_logic_vector(15 downto 0) := x"0000";
	signal s_res : std_logic_vector(31 downto 0);
begin

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
			elsif i_clk_enable = '1' then
				s_in_d <= i_data;
				s_out_d <= s_out;
			end if;
		end if;
	end process;

	s_res <= s_out_d * CONST;
	s_out <= s_res(31 downto 16) + (i_data - s_in_d);
	o_q <= s_out;

end behavioral;

/********************************************************/

-- @todo currently not working

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity low_pass_fir is
	generic
	(
		CONST : std_logic_vector(15 downto 0) := x"D0D0"
	);
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic := '1';
		i_reset_n : in std_logic := '1';
		i_data : in std_logic_vector(15 downto 0);
		o_q : out std_logic_vector(15 downto 0)
	);
end low_pass_fir;

architecture behavioral of low_pass_fir is
	signal s_gurke : std_logic_vector(15 downto 0);
	signal s_out : std_logic_vector(15 downto 0) := x"0000";
	signal s_out_d : std_logic_vector(15 downto 0) := x"0000";
	signal s_res : std_logic_vector(31 downto 0);
begin

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
			elsif i_clk_enable = '1' then
				s_out_d <= s_out;
			end if;
		end if;
	end process;
	
	s_gurke <= i_data - s_out_d;
	s_res <= s_gurke * CONST;
	s_out <= s_res(31 downto 16);
	o_q <= s_out;

end behavioral;
