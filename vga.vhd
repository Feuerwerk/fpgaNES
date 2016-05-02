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
use ieee.numeric_std.all;

entity vga is
	generic
	(
		HFP : natural := 88;
		HSYNC : natural := 44;
		HBP : natural := 148;
		HRES : natural := 1920;
		VFP : natural := 4;
		VSYNC : natural := 5;
		VBP : natural := 36;
		VRES : natural := 1080
	);
	port
	(
		i_data_clk : in std_logic;
		i_data_clk_enable : in std_logic;
		i_vga_clk : in std_logic;
		i_vga_clk_enable : in std_logic;
		i_reset_n : in std_logic;
		i_addr : in std_logic_vector(15 downto 0);
		i_data : in std_logic_vector(5 downto 0);
		i_write_enable : in std_logic;
		o_data_enable : out std_logic;
		o_vsync : out std_logic;
		o_hsync : out std_logic;
		o_data : out std_logic_vector(23 downto 0)
	);
end vga;

architecture behavioral of vga is
	component frmmem is
		port
		(
			data : in std_logic_vector(5 downto 0);
			rdaddress : in std_logic_vector(15 downto 0);
			rdclock : in std_logic;
			rdclocken : in std_logic;
			wraddress : in std_logic_vector(15 downto 0);
			wrclock : in std_logic := '1';
			wrclocken : in std_logic;
			wren : in std_logic := '0';
			q : out std_logic_vector(5 downto 0)
		);
	end component;

	type color_channel_t is array (0 to 63) of std_logic_vector(7 downto 0);
	constant red_channel: color_channel_t := (
		x"54", x"00", x"08", x"30", x"44", x"5C", x"54", x"3C", x"20", x"08", x"00", x"00", x"00", x"00", x"00", x"00",
		x"98", x"08", x"30", x"5C", x"88", x"A0", x"98", x"78", x"54", x"28", x"08", x"00", x"00", x"00", x"00", x"00",
		x"EC", x"4C", x"78", x"B0", x"E4", x"EC", x"EC", x"D4", x"A0", x"74", x"4C", x"38", x"38", x"3C", x"00", x"00",
		x"EC", x"A8", x"BC", x"D4", x"EC", x"EC", x"EC", x"E4", x"CC", x"B4", x"A8", x"98", x"A0", x"A0", x"00", x"00"
	);
	
	constant green_channel: color_channel_t := (
		x"54", x"1E", x"10", x"00", x"00", x"00", x"04", x"18", x"2A", x"3A", x"40", x"3C", x"32", x"00", x"00", x"00",
		x"96", x"4C", x"32", x"1E", x"14", x"14", x"22", x"3C", x"5A", x"72", x"7C", x"76", x"66", x"00", x"00", x"00",
		x"EE", x"9A", x"7C", x"62", x"54", x"58", x"6A", x"88", x"AA", x"C4", x"D0", x"CC", x"B4", x"3C", x"00", x"00",
		x"EE", x"CC", x"BC", x"B2", x"AE", x"AE", x"B4", x"C4", x"D2", x"DE", x"E2", x"E2", x"D6", x"A2", x"00", x"00"
	);
	
	constant blue_channel: color_channel_t := (
		x"54", x"74", x"90", x"88", x"64", x"30", x"00", x"00", x"00", x"00", x"00", x"00", x"3C", x"00", x"00", x"00",
		x"98", x"C4", x"EC", x"E4", x"B0", x"64", x"20", x"00", x"00", x"00", x"00", x"28", x"78", x"00", x"00", x"00",
		x"EC", x"EC", x"EC", x"EC", x"EC", x"B4", x"64", x"20", x"00", x"00", x"20", x"6C", x"CC", x"3C", x"00", x"00",
		x"EC", x"EC", x"EC", x"EC", x"EC", x"D4", x"B0", x"90", x"78", x"78", x"90", x"B4", x"E4", x"A0", x"00", x"00"
	);
	
	-- http://www.3dexpress.de/displayconfigx/timings.html
	
	/*
	640x480 25.175 MHz Pixel Clock
	HFP: natural := 16;
	HBP: natural := 48;
	HSYNC: natural := 96;
	HRES: natural := 640;
	VFP: natural := 10;
	VBP: natural := 33;
	VSYNC: natural := 2;
	VRES: natural := 480;
	*/
	
	/*
	1280x720 74.25 MHz Pixel Clock
	HFP: natural := 72;
	HSYNC: natural := 80;
	HBP: natural := 216;
	HRES: natural := 1280;
	VFP: natural := 3;
	VSYNC: natural := 5;
	VBP: natural := 22;
	VRES: natural := 720;
	*/

	/*
	1920x1080 148.5 MHz Pixel Clock
	HFP : natural := 88;
	HSYNC : natural := 44;
	HBP : natural := 148;
	HRES : natural := 1920;
	VFP : natural := 4;
	VSYNC : natural := 5;
	VBP : natural := 36;
	VRES : natural := 1080
	*/

					
	constant HSYNC_START : natural := HFP;
	constant HSYNC_STOP : natural := HFP + HSYNC;
	constant VSYNC_START : natural := VFP;
	constant VSYNC_STOP : natural := VFP + VSYNC;
	
	constant HACT_START : natural := HFP + HBP + HSYNC;
	constant HACT_STOP : natural := 0;
	constant VACT_START : natural := VFP + VBP + VSYNC;
	constant VACT_STOP : natural := 0;
	
	constant HMAX : natural := HFP + HBP + HSYNC + HRES - 1;
	constant VMAX : natural := VFP + VBP + VSYNC + VRES - 1;
	
	signal s_red : std_logic_vector(7 downto 0) := (others => '0');
	signal s_green : std_logic_vector(7 downto 0) := (others => '0');
	signal s_blue : std_logic_vector(7 downto 0) := (others => '0');
	signal s_addr : std_logic_vector(15 downto 0) := x"0000";
	signal s_data : std_logic_vector(5 downto 0);
	signal s_palette_index : integer range 0 to 63;
	signal s_hpos : natural range 0 to HMAX := 0;
	signal s_vpos : natural range 0 to VMAX := 0;
	signal s_data_enable : std_logic := '0';
	signal s_xpos : std_logic_vector(9 downto 0);
	signal s_ypos : std_logic_vector(9 downto 0);
	signal s_hsync : std_logic := '1';
	signal s_vsync : std_logic := '1';
	signal s_hact : std_logic := '0';
	signal s_vact : std_logic := '0';

begin
	framebuffer: frmmem port map
	(
		data => i_data,
		rdaddress => s_addr,
		rdclock => i_vga_clk,
		rdclocken => i_vga_clk_enable,
		wraddress => i_addr,
		wrclock => i_data_clk,
		wrclocken => i_data_clk_enable,
		wren => i_write_enable,
		q => s_data
	);
	
	-- Horizontal / Vertical Position
	
	process (i_vga_clk)
	begin
		if rising_edge(i_vga_clk) then
			if i_vga_clk_enable = '1' then
				if i_reset_n = '0' then
					s_hpos <= 0;
					s_vpos <= 0;
				elsif s_hpos = HMAX then
					s_hpos <= 0;
					
					if s_vpos = VMAX then
						s_vpos <= 0;
					else
						s_vpos <= s_vpos + 1;
					end if;
				else
					s_hpos <= s_hpos + 1;
				end if;
			end if;
		end if;
	end process;
	
	-- Horizontal Sync
	
	process (i_vga_clk)
	begin
		if rising_edge(i_vga_clk) then
			if i_vga_clk_enable = '1' then
				if i_reset_n = '0' then
					s_hsync <= '1';
				elsif s_hpos = HSYNC_START then
					s_hsync <= '0';
				elsif s_hpos = HSYNC_STOP then
					s_hsync <= '1';
				end if;
			end if;
		end if;
	end process;
	
	-- Vertical Sync
	
	process (i_vga_clk)
	begin
		if rising_edge(i_vga_clk) then
			if i_vga_clk_enable = '1' then
				if i_reset_n = '0' then
					s_vsync <= '1';
				elsif s_vpos = VSYNC_START then
					s_vsync <= '0';
				elsif s_vpos = VSYNC_STOP then
					s_vsync <= '1';
				end if;
			end if;
		end if;
	end process;
	
	-- Horizontal Actual View
	
	process (i_vga_clk)
	begin
		if rising_edge(i_vga_clk) then
			if i_vga_clk_enable = '1' then
				if i_reset_n = '0' then
					s_hact <= '0';
				elsif s_hpos = HACT_START then
					s_hact <= '1';
				elsif s_hpos = HACT_STOP then
					s_hact <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-- Vertical Actual View
	
	process (i_vga_clk)
	begin
		if rising_edge(i_vga_clk) then
			if i_vga_clk_enable = '1' then
				if i_reset_n = '0' then
					s_vact <= '0';
				elsif s_vpos = VACT_START then
					s_vact <= '1';
				elsif s_vpos = VACT_STOP then
					s_vact <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-- @todo ugly, do a complete rewrite of this process
						
	process (i_vga_clk)
	begin
		if rising_edge(i_vga_clk) then
			if i_vga_clk_enable = '1' then
				if i_reset_n = '0' then
					s_xpos <= (others => '0');
					s_ypos <= (others => '0');
					s_red <= x"00";
					s_green <= x"00";
					s_blue <= x"00";
				else
					if s_hpos >= HFP + HBP + HSYNC + 62 then
						s_xpos <= std_logic_vector(to_unsigned(s_hpos - HFP - HBP - HSYNC - 62, 10));
					else
						s_xpos <= (others => '0');
					end if;
					
					if s_vpos >= VFP + VBP + VSYNC then
						s_ypos <= std_logic_vector(to_unsigned(s_vpos - VFP - VBP - VSYNC, 10));
					else
						s_ypos <= (others => '0');
					end if;
					
					if (s_hpos >= HFP + HBP + HSYNC + 64) and (s_hpos < HMAX - 64) and (s_vpos >= VFP + VBP + VSYNC) then
						s_red <= red_channel(s_palette_index);
						s_green <= green_channel(s_palette_index);
						s_blue <= blue_channel(s_palette_index);
					else
						s_red <= x"00";
						s_green <= x"00";
						s_blue <= x"00";
					end if;
				end if;
			end if;
		end if;
	end process;

	s_palette_index <= to_integer(unsigned(s_data));
	s_addr <= s_ypos(8 downto 1) & s_xpos(8 downto 1);

	o_data <= s_red & s_green & s_blue/* when s_data_enable = '1' else x"000000"*/;
	o_data_enable <= s_hact and s_vact;
	o_hsync <= s_hsync;
	o_vsync <= s_vsync;

end architecture;
