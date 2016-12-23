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
		i_data : in std_logic_vector(8 downto 0);
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
			data : in std_logic_vector(8 downto 0);
			rdaddress : in std_logic_vector(15 downto 0);
			rdclock : in std_logic;
			rdclocken : in std_logic;
			wraddress : in std_logic_vector(15 downto 0);
			wrclock : in std_logic := '1';
			wrclocken : in std_logic;
			wren : in std_logic := '0';
			q : out std_logic_vector(8 downto 0)
		);
	end component;
	
	type color_t is array (0 to 511) of std_logic_vector(23 downto 0);
	
	constant PALETTE : color_t := (
		x"656565", x"00298a", x"1a14a8", x"3d05a1", x"5c0077", x"6c0239", x"680d00", x"512000", x"2f3600", x"0d4700", x"004f00", x"004c11", x"003d51", x"000000", x"050505", x"050505", 
		x"b1b1b1", x"1b5ce5", x"473eff", x"7927ff", x"a41dcb", x"bb2274", x"b5341b", x"965000", x"666f00", x"348700", x"0f9300", x"008e39", x"027a95", x"050505", x"050505", x"050505", 
		x"ffffff", x"67afff", x"988fff", x"ce75ff", x"fc6aff", x"ff6fc8", x"ff8368", x"eca21f", x"bac300", x"84dd06", x"59ea35", x"44e489", x"49cfec", x"4d4d4d", x"050505", x"050505", 
		x"ffffff", x"c5e4ff", x"dad6ff", x"f1cbff", x"ffc6ff", x"ffc8ee", x"ffd1c5", x"fddea4", x"e8ec93", x"d1f797", x"bffcae", x"b5fad4", x"b8f1fd", x"b9b9b9", x"050505", x"050505", 
		x"66423b", x"000f5a", x"190177", x"3b0074", x"580053", x"690022", x"680400", x"521100", x"312100", x"112d00", x"003100", x"002b00", x"001d28", x"000000", x"060000", x"060000", 
		x"b37f74", x"1c35a0", x"461fc8", x"7610c4", x"9f0b97", x"b61250", x"b6240a", x"963900", x"694f00", x"396000", x"156600", x"035e12", x"034a5a", x"060000", x"060000", x"060000", 
		x"ffc5b7", x"6976e5", x"985eff", x"cb4dff", x"f747db", x"ff4f91", x"ff6443", x"ee7a05", x"bd9300", x"8aa500", x"61ab0c", x"4ba34d", x"4b8d9b", x"4e302a", x"060000", x"060000", 
		x"ffc5b7", x"c7a4ca", x"db9adb", x"f193d9", x"ff90c6", x"ff93a7", x"ff9d86", x"ffa669", x"ebb059", x"d5b85b", x"c3bb6d", x"b9b78a", x"baaeab", x"bb867b", x"060000", x"060000", 
		x"375d2e", x"002357", x"000f6d", x"190164", x"2f003f", x"3f0010", x"3e0900", x"2e1c00", x"153100", x"004300", x"004d00", x"004700", x"00382a", x"000000", x"000200", x"000200", 
		x"6fa560", x"00549a", x"1d36ba", x"431fae", x"631379", x"791a35", x"782e00", x"624900", x"3d6800", x"188100", x"008f00", x"008714", x"00715b", x"000200", x"000200", x"000200", 
		x"aff99c", x"33a3d9", x"5783f9", x"8069ed", x"a35bb6", x"ba646d", x"b97923", x"a19800", x"7bb800", x"51d300", x"32e209", x"1dd948", x"1ec396", x"26461e", x"000200", x"000200", 
		x"aff99c", x"7ad5b5", x"8ac8c2", x"9cbdbd", x"aab7a7", x"b4ba89", x"b3c468", x"aad14f", x"99de43", x"88ea47", x"7af05c", x"70ec79", x"71e39a", x"75ad66", x"000200", x"000200", 
		x"3e3f25", x"000e49", x"04015e", x"1c0059", x"31003c", x"41000d", x"400200", x"300f00", x"181e00", x"012a00", x"003000", x"002a00", x"001c21", x"000000", x"000000", x"000000", 
		x"797a54", x"063387", x"241ea5", x"470e9e", x"660875", x"7c0e31", x"7c2000", x"653500", x"434b00", x"1f5d00", x"056500", x"005d09", x"00484f", x"000000", x"000000", x"000000", 
		x"bdbf8a", x"3f73c0", x"615cdf", x"884ad8", x"a942ad", x"c14965", x"c05e1b", x"a87500", x"838d00", x"5ca000", x"3ea800", x"29a038", x"298a85", x"2c2d17", x"000000", x"000000", 
		x"bdbf8a", x"87a0a0", x"9795ad", x"a78eaa", x"b58a99", x"bf8e7b", x"be975b", x"b4a044", x"a5aa39", x"94b23b", x"87b64b", x"7eb268", x"7ea988", x"7f8159", x"000000", x"000000", 
		x"48457d", x"001a93", x"120bb0", x"2d00a7", x"440080", x"4f0046", x"49000c", x"330a00", x"151900", x"002900", x"003300", x"003321", x"00295e", x"000000", x"00000e", x"00000e", 
		x"8783d5", x"1146f3", x"3930ff", x"6119ff", x"820ed8", x"910e87", x"881a34", x"6a2d00", x"3e4300", x"195c00", x"00690c", x"006953", x"005ba8", x"00000e", x"00000e", x"00000e", 
		x"d0cbff", x"508aff", x"7d72ff", x"a858ff", x"cb4bff", x"db4ce7", x"d2598d", x"b16f47", x"828724", x"59a12e", x"39b05f", x"2bafaf", x"33a1ff", x"343262", x"00000e", x"00000e", 
		x"d0cbff", x"9ab0ff", x"ada6ff", x"bf9bff", x"ce95ff", x"d495ff", x"d19bf1", x"c3a5d2", x"b0afc1", x"9ebac6", x"90c0dd", x"89c0ff", x"8dbaff", x"8e8ade", x"00000e", x"00000e", 
		x"46344b", x"000b60", x"10007c", x"2a0077", x"400059", x"4b002c", x"480000", x"330500", x"151400", x"002000", x"002500", x"002301", x"00192d", x"000000", x"000000", x"000000", 
		x"856a8c", x"0f2ea9", x"3719d0", x"5c0ac9", x"7c039f", x"8c065f", x"88121e", x"692500", x"3d3b00", x"1a4d00", x"015500", x"005120", x"004362", x"000000", x"000000", x"000000", 
		x"cda9d7", x"4d69f5", x"7b51ff", x"a240ff", x"c437eb", x"d53ba8", x"d04961", x"b05f1e", x"817700", x"5a8a04", x"3c9226", x"2d8e63", x"307faa", x"332438", x"000000", x"000000", 
		x"cda9d7", x"978ee4", x"ab84f4", x"bc7cf2", x"c979e0", x"d07ac4", x"cf80a5", x"c18a87", x"ae9477", x"9d9c7a", x"8f9f8b", x"899ea6", x"8a97c5", x"8c7093", x"000000", x"000000", 
		x"304144", x"00165f", x"000875", x"16006c", x"2c0047", x"37001b", x"350000", x"250900", x"0e1700", x"002800", x"003200", x"002f08", x"002536", x"000000", x"000000", x"000000", 
		x"637d82", x"003fa7", x"192ac6", x"3f13ba", x"5f0885", x"6f0b46", x"6b1809", x"542b00", x"334100", x"0e5a00", x"006700", x"00632b", x"00556e", x"000000", x"000000", x"000000", 
		x"a0c2c9", x"2e81f1", x"5069ff", x"7950ff", x"9b43cd", x"ac468a", x"a85545", x"906b11", x"6c8300", x"439d03", x"24ab2f", x"16a76c", x"1a98b4", x"202e32", x"000000", x"000000", 
		x"a0c2c9", x"70a7da", x"7e9de6", x"9092e1", x"9e8ccb", x"a58eaf", x"a39491", x"999e79", x"8aa86d", x"79b372", x"6bb987", x"65b7a2", x"66b1c0", x"698389", x"000000", x"000000", 
		x"343434", x"000b4e", x"010064", x"19005f", x"2e0041", x"390016", x"360000", x"260500", x"0f1400", x"002000", x"002500", x"002300", x"001926", x"000000", x"000000", x"000000", 
		x"6a6a6a", x"022e8f", x"1f19ad", x"430aa6", x"61037d", x"71063f", x"6d1202", x"572600", x"353b00", x"124d00", x"005500", x"005116", x"004356", x"000000", x"000000", x"000000", 
		x"a9a9a9", x"3669d0", x"5852ef", x"7f40e8", x"9f38bd", x"b03b7b", x"ac4a36", x"945f05", x"707700", x"4a8a00", x"2c9213", x"1e8f4e", x"217f94", x"242424", x"000000", x"000000", 
		x"a9a9a9", x"788eb9", x"8784c6", x"977cc3", x"a579b1", x"ac7a96", x"aa8178", x"a08a61", x"919455", x"819c58", x"74a068", x"6d9e83", x"6f98a0", x"707070", x"000000", x"000000"
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
	signal s_addr : std_logic_vector(15 downto 0) := (others => '0');
	signal s_pixel : std_logic_vector(8 downto 0);
	signal s_data : std_logic_vector(23 downto 0) := (others => '0');
	signal s_palette_index : integer range 0 to 63;
	signal s_hpos : natural range 0 to HMAX := 0;
	signal s_vpos : natural range 0 to VMAX := 0;
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
		q => s_pixel
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
					s_data <= (others => '0');
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
						s_data <= PALETTE(s_palette_index);
					else
						s_data <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

	s_palette_index <= to_integer(unsigned(s_pixel));
	s_addr <= s_ypos(8 downto 1) & s_xpos(8 downto 1);

	o_data <= s_data;
	o_data_enable <= s_hact and s_vact;
	o_hsync <= s_hsync;
	o_vsync <= s_vsync;

end architecture;
