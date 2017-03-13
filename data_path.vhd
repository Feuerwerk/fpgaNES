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

-- this component get accessed by the cpu if a value should be read from
-- memory or be written to. it covers the complete cpu address space
-- and redirects the requests to the specific sub modules like
-- the program ROM, the RAM, the PPU- or APU-ports

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity data_path is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic := '1';
		i_reset_n : in std_logic;
		i_sync : in std_logic;
		i_addr : in std_logic_vector(15 downto 0);
		i_data : in std_logic_vector(7 downto 0);
		i_write_enable : in std_logic;
		i_ppu_q : in std_logic_vector(7 downto 0);
		i_apu_q : in std_logic_vector(7 downto 0);
		i_prg_q : in std_logic_vector(7 downto 0);
		o_prg_addr : out std_logic_vector(14 downto 0);
		o_prg_cs_n : out std_logic;
		o_ppu_addr : out std_logic_vector(2 downto 0);
		o_ppu_cs_n : out std_logic;
		o_apu_addr : out std_logic_vector(4 downto 0);
		o_apu_cs_n : out std_logic;
		o_q : out std_logic_vector(7 downto 0)
	);
end data_path;

architecture behavioral of data_path is
	component datamem is
		port
		(
			address : in std_logic_vector(10 downto 0);
			clken : in std_logic := '1';
			clock : in std_logic := '1';
			data : in std_logic_vector(7 downto 0);
			wren : in std_logic;
			q : out std_logic_vector(7 downto 0)
		);
	end component;
	
	type addr_type_t is (nop, ram, rom, ppu, apu);
	
	signal s_prgram_addr : std_logic_vector(10 downto 0);
	signal s_prgram_q : std_logic_vector(7 downto 0);
	signal s_prgram_write_enable : std_logic;
	signal s_curr_addr : std_logic_vector(15 downto 0);
	signal s_ppu_addr : std_logic_vector(14 downto 0);
	signal s_addr_type : addr_type_t;
	signal s_addr_type_d : addr_type_t := nop;
	
begin
	prgram : datamem port map
	(
		address => s_prgram_addr,
		clken => i_clk_enable,
		clock => i_clk,
		data => i_data,
		wren => s_prgram_write_enable,
		q => s_prgram_q
	);

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				s_addr_type_d <= s_addr_type;
			end if;
		end if;
	end process;

	s_addr_type <= ppu when i_addr(15 downto 13) = "001"
						else ram when i_addr(15 downto 13) = "000"
						else apu when i_addr(15 downto 5) = "01000000000"
						else rom;
						
	with s_addr_type_d select o_q <=
		s_prgram_q when ram,
		i_ppu_q when ppu,
		i_apu_q when apu,
		i_prg_q when others;
	
	s_prgram_addr <= i_addr(10 downto 0);
	s_prgram_write_enable <= i_write_enable when s_addr_type = ram else '0';

	o_ppu_addr <= i_addr(2 downto 0);
	o_apu_addr <= i_addr(4 downto 0);
	o_prg_addr <= i_addr(14 downto 0);
	
	o_ppu_cs_n <= not i_sync when s_addr_type = ppu else '1';
	o_apu_cs_n <= not i_clk_enable when s_addr_type = apu else '1';
	o_prg_cs_n <= i_sync nand i_addr(15);
	
end;
