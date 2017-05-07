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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity parallel_serial_shifter is
	generic
	(
		width: integer := 8;
		size: integer := 8
	);
	port
	(
		i_clk: in std_logic;
		i_clk_enable : in std_logic := '1';
		i_load: in std_logic;
		i_enable: in std_logic;
		i_data: in std_logic_vector(size - 1 downto 0);
		o_q: out std_logic_vector(size - 1 downto 0)
	);
end parallel_serial_shifter;

architecture behavioral of parallel_serial_shifter is
	signal s_buffer: std_logic_vector(width - 1 downto 0);
begin
	process (i_clk, i_clk_enable)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_enable = '1' and i_load = '1' then
					s_buffer <= s_buffer(width - 2 downto size) & i_data & '0';
				elsif i_enable = '1' then
					s_buffer <= s_buffer(width - 2 downto 0) & '0';
				elsif i_load = '1' then
					s_buffer(size - 1 downto 0) <= i_data;
				end if;
			end if;
		end if;
	end process;
	
	o_q <= reverse_vector(s_buffer(width - 1 downto width - size));
end architecture;

/*****************************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sprite_renderer is
	port
	(
		i_sprite_x : in std_logic_vector(7 downto 0);
		i_line_x : in std_logic_vector(7 downto 0);
		i_tile_low : in std_logic_vector(7 downto 0);
		i_tile_high : in std_logic_vector(7 downto 0);
		i_enable : in std_logic;
		i_first_col : in std_logic;
		o_pixel : out std_logic_vector(1 downto 0)
	);
end sprite_renderer;

architecture behavioral of sprite_renderer is
	signal s_offset : integer range 0 to 7;
	signal s_sprite_right : std_logic_vector(8 downto 0);
	signal s_draw_n : boolean;
begin

	s_offset <= to_integer(unsigned(i_sprite_x(2 downto 0) - i_line_x(2 downto 0) - "001"));
	s_sprite_right <= ('0' & i_sprite_x) + "000001000";
	s_draw_n <= (i_first_col = '0') and (i_line_x(7 downto 3) = "00000");

	o_pixel <= "00" when (i_enable = '0') or s_draw_n or (i_line_x < i_sprite_x) or (i_line_x >= s_sprite_right) else i_tile_high(s_offset) & i_tile_low(s_offset);
	
end architecture;

/*****************************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity ppu is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic := '1';
		i_reset_n : in std_logic := '1';
		i_video_mode : in video_mode_t := ntsc;
		i_addr : in std_logic_vector(2 downto 0) := "000";
		i_data : in std_logic_vector(7 downto 0) := x"00";
		i_write_enable : in std_logic := '0';
		i_cs_n : in std_logic := '0';
		i_chr_data : in std_logic_vector(7 downto 0) := x"00";
		o_q : out std_logic_vector(7 downto 0);
		o_int_n : out std_logic;
		o_vga_addr : out std_logic_vector(15 downto 0);
		o_vga_data : out std_logic_vector(8 downto 0);
		o_vga_write_enable : out std_logic;
		o_chr_addr : out std_logic_vector(13 downto 0);
		o_chr_read_enable : out std_logic;
		o_chr_write_enable : out std_logic;
		o_chr_q : out std_logic_vector(7 downto 0)
	);
end ppu;

architecture behavioral of ppu is
	component parallel_serial_shifter is
		generic
		(
			width: integer := 8;
			size: integer := 8
		);
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_load : in std_logic;
			i_enable : in std_logic;
			i_data : in std_logic_vector(7 downto 0);
			o_q : out std_logic_vector(7 downto 0)
		);
	end component;
	component spritemem is
		port
		(
			address : in std_logic_vector(7 downto 0);
			clken : in std_logic := '1';
			clock : in std_logic := '1';
			data : in std_logic_vector(7 downto 0);
			wren : in std_logic := '0';
			q : out std_logic_vector(7 downto 0)
		);
	end component;
	component soamem is
		port
		(
			address : in std_logic_vector(4 downto 0);
			clken : in std_logic := '1';
			clock : in std_logic := '1';
			data : in std_logic_vector(7 downto 0);
			wren : in std_logic;
			q : out std_logic_vector(7 downto 0)
		);
	end component;
	component sprite_renderer is
		port
		(
			i_sprite_x : in std_logic_vector(7 downto 0);
			i_line_x : in std_logic_vector(7 downto 0);
			i_tile_low : in std_logic_vector(7 downto 0);
			i_tile_high : in std_logic_vector(7 downto 0);
			i_enable : in std_logic;
			i_first_col : in std_logic;
			o_pixel : out std_logic_vector(1 downto 0)
		);
	end component;
	
	function to_pal_idx(addr: std_logic_vector(4 downto 0)) return integer is
	begin
		if (addr(4) = '1') and (addr(1 downto 0) = "00") then
			return to_integer(unsigned('0' & addr(3 downto 0)));
		else
			return to_integer(unsigned(addr));
		end if;
	end;

	type sprite_t is record
		x : std_logic_vector(7 downto 0);
		tile_low : std_logic_vector(7 downto 0);
		tile_high : std_logic_vector(7 downto 0);
		priority : std_logic;
		palette : std_logic_vector(1 downto 0);
		pixel : std_logic_vector(1 downto 0);
	end record;
	
	type io_state_t is (idle, ppuctrl, ppumask, ppustatus, oamaddr, oamdata_read, oamdata_write, ppuscroll_x, ppuscroll_y, ppuaddr_hi, ppuaddr_lo, ppudata_read, ppudata_write);
	type sprite_memory_t is (oam, soa);
	type sprite_state_t is (idle, clear1, clear2, ev_y1, ev_y2, ev_tile1, ev_tile2, ev_attr1, ev_attr2, ev_x1, ev_x2, of_y1, of_y2, of_title1, of_title2, of_attr1, of_attr2, of_x1, of_x2, wait1a, wait1b, wait_eol, gf1, gf2, gf3, gf4, ftl1, ftl2, fth1, fth2);
	type background_state_t is (idle, nt1, nt2, at1, at2, tl1, tl2, th1, th2);
	type sprite_list_t is array (0 to 7) of sprite_t;
	type byte_array_t is array (0 to 31) of std_logic_vector(5 downto 0);
	
	constant NULL_SPRITE : sprite_t := (x => x"00", tile_low => x"00", tile_high => x"00", priority => '0', palette => "00", pixel => "00");
	constant SKIP_DOT_CYCLE : integer := 339;
	constant ENABLE_NMI_WRITE_CYCLE : integer := 0;
	constant PPUSTATUS_READ_CYCLE : integer := 0;
	constant VBLANK_SET_CYCLE : integer := 1;
	constant VBLANK_CLEAR_CYCLE : integer := 1;
	constant SPR0HIT_CLEAR_CYCLE : integer := 0;
	constant SPROVFW_CLEAR_CYCLE : integer := 0;
	constant MAX_DECAY : integer := 3192000;
	
	type decay_array_t is array (0 to 7) of integer range 0 to MAX_DECAY;

	signal s_io_state : io_state_t := idle;
	signal s_io_data : std_logic_vector(7 downto 0) := x"00";
	signal s_io_mem : std_logic_vector(7 downto 0) := x"00";
	signal s_io_cycle : integer range 0 to 7 := 0;
	signal s_io_latch : boolean := true;
	signal s_sprites : sprite_list_t := (others => NULL_SPRITE);
	signal s_spr_mem : sprite_memory_t := oam;
	signal s_spr_mem_d : sprite_memory_t := oam;
	signal s_oam_clk_enable : std_logic;
	signal s_oam_addr : std_logic_vector(7 downto 0) := x"00";
	signal s_oam_write_enable : std_logic;
	signal s_oam_eff_q : std_logic_vector(7 downto 0);
	signal s_oam_q : std_logic_vector(7 downto 0);
	signal s_soa_clk_enable : std_logic;	
	signal s_soa_addr : std_logic_vector(4 downto 0) := (others => '0');
	signal s_soa_q : std_logic_vector(7 downto 0) := (others => '0');
	signal s_soa_write_enable : std_logic := '0';
	signal s_spr_addr : std_logic_vector(15 downto 0) := (others => '0');
	signal s_bkg_addr : std_logic_vector(15 downto 0) := (others => '0');
	signal s_spr_read_enable : std_logic := '0';
	signal s_bkg_read_enable : std_logic := '0';
	signal s_video_addr : std_logic_vector(15 downto 0) := (others => '0');
	signal s_video_read_enable : std_logic;
	signal s_video_write_enable : std_logic;
	signal s_xpos : std_logic_vector(7 downto 0);
	signal s_ypos : std_logic_vector(7 downto 0);
	signal s_cycle : integer range 0 to 340 := 0;
	signal s_line : integer range 0 to 311 := 311;
	signal s_max_line : integer range 0 to 311 := 261;
	signal s_new_max_line : integer range 0 to 311;
	signal s_tile_index : std_logic_vector(7 downto 0);
	signal s_background_half : std_logic := '0';
	signal s_sprite_half : std_logic := '0';
	signal s_shifter_enable : std_logic := '0';
	signal s_shifter_load : std_logic := '0';
	signal s_render : boolean;
	signal s_tl_data : std_logic_vector(7 downto 0) := (others => '0');
	signal s_tl_q : std_logic_vector(7 downto 0);
	signal s_th_data : std_logic_vector(7 downto 0) := (others => '0');
	signal s_th_q : std_logic_vector(7 downto 0);
	signal s_bl_q : std_logic_vector(7 downto 0);
	signal s_bh_q : std_logic_vector(7 downto 0);
	signal s_background_palette_index: std_logic_vector(1 downto 0);
	signal s_new_background_palette_index : std_logic_vector(1 downto 0);
	signal s_color : std_logic_vector(5 downto 0);
	signal s_palette_color : std_logic_vector(5 downto 0);
	signal s_bkg_state : background_state_t := idle;
	signal s_spr_state : sprite_state_t := idle;
	signal s_out_addr : std_logic_vector(15 downto 0) := x"0000";
	signal s_out_data : std_logic_vector(8 downto 0);
	signal s_out_color : std_logic_vector(5 downto 0);
	signal s_out_write_enable : std_logic := '0';
	signal s_visible_line : boolean;
	signal s_visible_or_prescan_line : boolean;
	signal s_prescan_line : boolean;
	signal s_background_pixel : std_logic_vector(1 downto 0);
	signal s_winning_sprite : sprite_t;
	signal s_spr_idx : integer range 0 to 7 := 0;
	signal s_spr_fill : integer range -1 to 7 := -1;
	signal s_sprite_y : std_logic_vector(8 downto 0) := (others => '0');
	signal s_sprite_tile : std_logic_vector(7 downto 0) := (others => '0');
	signal s_sprite_disable : std_logic;
	signal s_sprite_0_hit : std_logic := '0';
	signal s_sprite_0_visible : boolean := false;
	signal s_new_sprite_0_visible : boolean := false;
	signal s_sprite_overflow : std_logic := '0';
	signal s_sprite_flip_horizontal : std_logic := '0';
	signal s_tile_data : std_logic_vector(7 downto 0);
	signal s_enable_background : std_logic := '0';
	signal s_enable_sprites : std_logic := '0';
	signal s_render_first_bkg_col : std_logic := '0';
	signal s_render_first_spr_col : std_logic := '0';
	signal s_big_sprites : std_logic := '0';
	signal s_sprite_online : boolean;
	signal s_sprite_line_lower_test : boolean;
	signal s_sprite_line_upper_test : boolean;
	signal s_sprite_line_test_height : std_logic_vector(7 downto 0);
	signal s_inner_tile_pos : std_logic_vector(3 downto 0);
	signal s_next_tile_addr : std_logic_vector(12 downto 0);
	signal s_tile_addr : std_logic_vector(15 downto 0);
	signal s_attr_addr : std_logic_vector(15 downto 0);
	signal s_tile_lo_addr : std_logic_vector(15 downto 0);
	signal s_tile_hi_addr : std_logic_vector(15 downto 0);
	signal s_vassign : boolean;
	signal s_q : std_logic_vector(7 downto 0) := x"00";
	signal s_perform_oam_write_access : boolean;
	signal s_perform_oam_access : boolean;
	signal s_vblank : std_logic := '0';
	signal s_enable_nmi : std_logic := '0';
	signal s_vram_inc : std_logic := '0';
	signal s_vram_addr_t : std_logic_vector(14 downto 0) := 15x"0000";
	signal s_vram_addr_v : std_logic_vector(14 downto 0) := 15x"0000";
	signal s_fine_scroll_x : integer range 0 to 7 := 0;
	signal s_palette_access : boolean;
	signal s_palette_index : std_logic_vector(4 downto 0);
	signal s_palette_quadrant : std_logic_vector(1 downto 0);
	signal s_palette_mem : byte_array_t := ( 6x"09", 6x"01", 6x"00", 6x"01", 6x"00", 6x"02", 6x"02", 6x"0D", 6x"08", 6x"10", 6x"08", 6x"24", 6x"00", 6x"00", 6x"04", 6x"2C", 6x"09", 6x"01", 6x"34", 6x"03", 6x"00", 6x"04", 6x"00", 6x"14", 6x"08", 6x"3A", 6x"00", 6x"02", 6x"00", 6x"20", 6x"2C", 6x"08" );
	signal s_hblank_cycle : boolean;
	signal s_first_col_n : boolean;
	signal s_vram_bkg_inc : boolean;
	signal s_frame_latch : boolean := true;
	signal s_enable_rendering : boolean;
	signal s_enable_shortcut : boolean := false;
	signal s_new_enable_shortcut : boolean;
	signal s_greyscale : std_logic := '0';
	signal s_color_emphasize : std_logic_vector(2 downto 0) := "000";
	signal s_skip_dot : boolean;
	signal s_last_cycle : boolean;
	signal s_q_decay : decay_array_t := (others => 0);
	signal s_decay_mask : std_logic_vector(7 downto 0) := (others => '0');
	signal s_oam_data : std_logic_vector(7 downto 0);

begin
	
	oamem: spritemem port map
	(
		clock => i_clk,
		clken => s_oam_clk_enable,
		address => s_oam_addr,
		data => s_oam_data,
		wren => s_oam_write_enable,
		q => s_oam_q
	);
	soam: soamem port map
	(
		clock => i_clk,
		clken => s_soa_clk_enable,
		address => s_soa_addr,
		data => s_oam_eff_q,
		wren => s_soa_write_enable,
		q => s_soa_q
	);
	tl_shifter: parallel_serial_shifter generic map (16, 8) port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_load => s_shifter_load,
		i_enable => s_shifter_enable,
		i_data => s_tl_data,
		o_q => s_tl_q
	);
	th_shifter: parallel_serial_shifter generic map (16, 8) port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_load => s_shifter_load,
		i_enable => s_shifter_enable,
		i_data => i_chr_data,
		o_q => s_th_q
	);
	bl_shifter: parallel_serial_shifter generic map (16, 8) port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_load => s_shifter_load,
		i_enable => s_shifter_enable,
		i_data => s_new_background_palette_index(0) & s_new_background_palette_index(0) & s_new_background_palette_index(0) & s_new_background_palette_index(0) & s_new_background_palette_index(0) & s_new_background_palette_index(0) & s_new_background_palette_index(0) & s_new_background_palette_index(0),
		o_q => s_bl_q
	);
	bh_shifter: parallel_serial_shifter generic map (16, 8) port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_load => s_shifter_load,
		i_enable => s_shifter_enable,
		i_data => s_new_background_palette_index(1) & s_new_background_palette_index(1) & s_new_background_palette_index(1) & s_new_background_palette_index(1) & s_new_background_palette_index(1) & s_new_background_palette_index(1) & s_new_background_palette_index(1) & s_new_background_palette_index(1),
		o_q => s_bh_q
	);

	spr_gen: for i in 0 to 7 generate
		spr: sprite_renderer port map
		(
			i_sprite_x => s_sprites(i).x,
			i_line_x => s_xpos,
			i_tile_low => s_sprites(i).tile_low,
			i_tile_high => s_sprites(i).tile_high,
			i_enable => s_enable_sprites,
			i_first_col => s_render_first_spr_col,
			o_pixel => s_sprites(i).pixel
		);
	end generate;
	
	-- IO

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				s_decay_mask <= (others => '0');
			
				if i_reset_n = '0' then
					s_q <= x"00";
					s_io_data <= x"00";
					s_io_state <= idle;
					s_io_latch <= true;
					s_q_decay <= (others => 0);
				else
					for i in 0 to 7 loop
						if s_decay_mask(i) = '1' then
							s_q_decay(i) <= MAX_DECAY;
						elsif s_q_decay(i) /= 0 then
							s_q_decay(i) <= s_q_decay(i) - 1;
						else
							s_q(i) <= '0';
						end if;
					end loop;
				
					case s_io_state is
					
						when idle =>
							if i_cs_n = '0' then
								s_io_data <= i_data;
								s_io_cycle <= 0;
								
								if i_write_enable = '1' then
									s_q <= i_data;
									s_decay_mask <= (others => '1');
								end if;

								case i_addr is
									
									when "000" => -- PPUCTRL
										if i_write_enable = '1' then
											s_io_state <= ppuctrl;
										end if;
									
									when "001" => -- PPUMASK
										if i_write_enable = '1' then
											s_io_state <= ppumask;
										end if;
									
									when "010" => -- PPUSTATUS
										if i_write_enable = '0' then
											s_io_state <= ppustatus;
											s_io_latch <= true;
										end if;
									
									when "011" => -- OAMADDR
										if i_write_enable = '1' then
											s_io_state <= oamaddr;
											s_io_data <= i_data;
										end if;
									
									when "100" => -- OAMDATA
										if i_write_enable = '1' then
											s_io_state <= oamdata_write;
										else
											s_io_state <= oamdata_read;
										end if;
									
									when "101" => -- PPUSCROLL
										if i_write_enable = '1' then
											if s_io_latch then
												s_io_state <= ppuscroll_x;
											else
												s_io_state <= ppuscroll_y;
											end if;
											
											s_io_latch <= not s_io_latch;
										end if;
									
									when "110" => -- PPUADDR
										if i_write_enable = '1' then
											if s_io_latch then
												s_io_state <= ppuaddr_hi;
											else
												s_io_state <= ppuaddr_lo;
											end if;
											
											s_io_latch <= not s_io_latch;
										end if;
									
									when "111" => -- PPUDATA
										if i_write_enable = '1' then
											s_io_state <= ppudata_write;
										else
											s_io_state <= ppudata_read;
										end if;
									
									when others =>
								
								end case;
							end if;
						
						when oamdata_read =>
							if s_io_cycle = 1 then
								s_io_state <= idle;
								s_decay_mask <= (others => '1');
								
								if s_spr_mem_d = oam then
									s_q <= s_oam_eff_q;
								else
									s_q <= s_soa_q;
								end if;
							else
								s_io_cycle <= s_io_cycle + 1;
							end if;
							
						when ppustatus =>
							if s_io_cycle = 2 then
								s_io_state <= idle;
							else
								if s_io_cycle = PPUSTATUS_READ_CYCLE then
									s_q(7 downto 5) <= s_vblank & s_sprite_0_hit & s_sprite_overflow;
									s_decay_mask(7 downto 5) <= (others => '1');
								end if;

								s_io_cycle <= s_io_cycle + 1;
							end if;
							
						when oamaddr | oamdata_write | ppuctrl | ppuscroll_x | ppuscroll_y | ppumask | ppuaddr_hi =>
							if s_io_cycle = 1 then
								s_io_state <= idle;
							else
								s_io_cycle <= s_io_cycle + 1;
							end if;
							
						when ppudata_read =>
							if s_io_cycle = 5 then
								s_io_state <= idle;
								s_io_mem <= i_chr_data;
							else
								if s_io_cycle = 1 then
									if s_palette_access then
										s_q(5 downto 0) <= s_palette_mem(to_pal_idx(s_vram_addr_v(4 downto 0)));
										s_decay_mask(5 downto 0) <= (others => '1');
									else
										s_q <= s_io_mem;
										s_decay_mask <= (others => '1');
									end if;
								end if;
							
								s_io_cycle <= s_io_cycle + 1;
							end if;
							
						when ppuaddr_lo =>
							if s_io_cycle = 2 then
								s_io_state <= idle;
							else
								s_io_cycle <= s_io_cycle + 1;
							end if;
							
						when ppudata_write =>
							if s_io_cycle = 7 then
								s_io_state <= idle;
							else
								s_io_cycle <= s_io_cycle + 1;
							end if;
					
					end case;
				end if;
			end if;
		end if;
	end process;

	-- Zeilen & Zyklen
	
	process (i_video_mode)
	begin
		case i_video_mode is
		
			when ntsc =>
				s_new_max_line <= 261;
				s_new_enable_shortcut <= true;
				
			when pal =>
				s_new_max_line <= 311;
				s_new_enable_shortcut <= false;
			
		end case;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_line <= s_new_max_line;
					s_max_line <= s_new_max_line;
					s_enable_shortcut <= s_new_enable_shortcut;
					s_cycle <= 0;
					s_frame_latch <= true;
				else
					if s_last_cycle then
						s_cycle <= 0;
						
						if s_prescan_line then
							s_line <= 0;
							s_max_line <= s_new_max_line;
							
							s_frame_latch <= not s_frame_latch;
							s_enable_shortcut <= s_new_enable_shortcut;
							
							if s_skip_dot then
								s_cycle <= 1;
							end if;
						else
							s_line <= s_line + 1;
						end if;
					else
						s_cycle <= s_cycle + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_skip_dot <= false;
				elsif s_prescan_line and s_last_cycle then
					s_skip_dot <= false;
				elsif s_prescan_line and (s_cycle = SKIP_DOT_CYCLE) and s_frame_latch and s_enable_rendering and s_enable_shortcut then
					s_skip_dot <= true;
				end if;
			end if;
		end if;
	end process;
	
	-- Enable Rendering
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_greyscale <= '0';
				elsif s_io_state = ppumask then
					s_greyscale <= s_io_data(0);
				end if;
			end if;
		end if;
	end process;

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_render_first_bkg_col <= '0';
				elsif s_io_state = ppumask then
					s_render_first_bkg_col <= s_io_data(1);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_render_first_spr_col <= '0';
				elsif s_io_state = ppumask then
					s_render_first_spr_col <= s_io_data(2);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_enable_background <= '0';
				elsif s_io_state = ppumask then
					s_enable_background <= s_io_data(3);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_enable_sprites <= '0';
				elsif s_io_state = ppumask then
					s_enable_sprites <= s_io_data(4);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_color_emphasize <= "000";
				elsif s_io_state = ppumask then
					case i_video_mode is
					
						when ntsc =>
							s_color_emphasize <= s_io_data(7 downto 5);
							
						when pal =>
							s_color_emphasize <= s_io_data(7) & s_io_data(5) & s_io_data(6);
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- Setup
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_vram_inc <= '0';
				elsif s_io_state = ppuctrl then
					s_vram_inc <= s_io_data(2);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_sprite_half <= '0';
				elsif s_io_state = ppuctrl then
					s_sprite_half <= s_io_data(3);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_background_half <= '0';
				elsif s_io_state = ppuctrl then
					s_background_half <= s_io_data(4);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_big_sprites <= '0';
				elsif s_io_state = ppuctrl then
					s_big_sprites <= s_io_data(5);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_enable_nmi <= '0';
				elsif (s_io_state = ppuctrl) and (s_io_cycle = ENABLE_NMI_WRITE_CYCLE) then
					s_enable_nmi <= s_io_data(7);
				end if;
			end if;
		end if;
	end process;
	
	-- VRAM Adressierung

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_vram_addr_t <= 15x"0000";
				elsif s_io_state = ppuaddr_hi then
					s_vram_addr_t(14) <= '0';
					s_vram_addr_t(13 downto 8) <= s_io_data(5 downto 0);
				elsif (s_io_state = ppuaddr_lo) and (s_io_cycle = 0) then
					s_vram_addr_t(7 downto 0) <= s_io_data;
				elsif s_io_state = ppuscroll_x then
					s_vram_addr_t(4 downto 0) <= s_io_data(7 downto 3);
				elsif s_io_state = ppuscroll_y then
					s_vram_addr_t(14 downto 12) <= s_io_data(2 downto 0);
					s_vram_addr_t(9 downto 5) <= s_io_data(7 downto 3);
				elsif s_io_state = ppuctrl then
					s_vram_addr_t(11 downto 10) <= s_io_data(1 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_fine_scroll_x <= 0;
				elsif s_io_state = ppuscroll_x then
					s_fine_scroll_x <= to_integer(unsigned(s_io_data(2 downto 0)));
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_vram_addr_v <= 15x"0000";
				elsif (s_io_state = ppuaddr_lo) and (s_io_cycle = 2) then
					s_vram_addr_v <= s_vram_addr_t;
				elsif ((s_io_state = ppudata_write) and (s_io_cycle = 7)) or ((s_io_state = ppudata_read) and (s_io_cycle = 5)) then
					if s_vram_inc = '0' then
						s_vram_addr_v <= s_vram_addr_v + 15x"0001";
					else
						s_vram_addr_v <= s_vram_addr_v + 15x"0020";
					end if;

					s_vram_addr_v(14) <= '0';
				elsif s_enable_rendering and s_visible_or_prescan_line and s_hblank_cycle then
					if s_cycle = 257 then -- Horizontal LoopyV <= Horizontal LoopyT
						s_vram_addr_v(10) <= s_vram_addr_t(10);
						s_vram_addr_v(4 downto 0) <= s_vram_addr_t(4 downto 0);
					elsif s_vassign then -- Vertical LoopyV <= Horizontal LoopyT
						s_vram_addr_v(9 downto 5) <= s_vram_addr_t(9 downto 5);
						s_vram_addr_v(14 downto 11) <= s_vram_addr_t(14 downto 11);
					end if;
				elsif s_enable_rendering and s_visible_or_prescan_line and s_vram_bkg_inc then
					-- Vertical LoopyV increment
					if s_cycle = 255 then
						if s_vram_addr_v(14 downto 12) = "111" then
							s_vram_addr_v(14 downto 12) <= "000";
							
							if s_vram_addr_v(9 downto 5) = "11101" then -- 29
								s_vram_addr_v(11) <= not s_vram_addr_v(11);
								s_vram_addr_v(9 downto 5) <= "00000";
							elsif s_vram_addr_v(9 downto 5) = "11111" then -- 31
								s_vram_addr_v(9 downto 5) <= "00000";
							else
								s_vram_addr_v(9 downto 5) <= s_vram_addr_v(9 downto 5) + "00001";
							end if;
						else
							s_vram_addr_v(14 downto 12) <= s_vram_addr_v(14 downto 12) + "001";
						end if;
					end if;
					
					-- Horizontal LoopyV increment
					if s_vram_addr_v(4 downto 0) = "11111" then
						s_vram_addr_v(4 downto 0) <= "00000";
						s_vram_addr_v(10) <= not s_vram_addr_v(10);
					else
						s_vram_addr_v(4 downto 0) <= s_vram_addr_v(4 downto 0) + "00001";
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- Palette

	process (i_clk)
		variable index : integer range 0 to 31;
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if (s_io_state = ppudata_write) and s_palette_access and (s_io_cycle = 1) then
					index := to_pal_idx(s_vram_addr_v(4 downto 0));
					s_palette_mem(index) <= s_io_data(5 downto 0);
				end if;
			end if;
		end if;
	end process;

	-- Hintergrund rendern
	
	process (i_clk)
		variable ypos : std_logic_vector(7 downto 0);
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				s_shifter_load <= '0';
				s_bkg_read_enable <= '0';
			
				if i_reset_n = '0' then
					s_bkg_state <= idle;
				else
					case s_bkg_state is
					
						when idle =>
							s_bkg_state <= nt1;
							s_bkg_addr <= s_tile_addr;
					
						when nt1 => -- Name Table
							s_bkg_state <= nt2;
							s_bkg_read_enable <= '1';
							
						when nt2 =>
							s_bkg_addr <= s_attr_addr;
							s_bkg_state <= at1;
							
						when at1 => -- Attribute Table
							s_tile_index <= i_chr_data;
							s_bkg_state <= at2;
							s_bkg_read_enable <= '1';
							
						when at2 =>
							if not s_last_cycle then
								s_bkg_state <= tl1;
								s_bkg_addr <= s_tile_lo_addr;
							elsif s_skip_dot then
								s_bkg_state <= nt1;
								s_bkg_addr <= s_tile_addr;
							else
								s_bkg_state <= idle;
							end if;
							
						when tl1 => -- Tile low
							s_bkg_state <= tl2;
							s_bkg_read_enable <= '1';
							
							case s_palette_quadrant is
							
								when "00" =>
									s_new_background_palette_index <= i_chr_data(1 downto 0);
									
								when "01" =>
									s_new_background_palette_index <= i_chr_data(3 downto 2);
									
								when "10" =>
									s_new_background_palette_index <= i_chr_data(5 downto 4);
									
								when "11" =>
									s_new_background_palette_index <= i_chr_data(7 downto 6);
									
								when others =>
									s_new_background_palette_index <= "00";
									
							end case;
							
						when tl2 =>
							s_bkg_state <= th1;
							s_bkg_addr <= s_tile_hi_addr;
							
						when th1 => -- Tile high
							s_bkg_state <= th2;
							s_bkg_read_enable <= '1';
							s_tl_data <= i_chr_data;
							
						when th2 =>
							s_shifter_load <= '1';
							s_bkg_state <= nt1;
							s_bkg_addr <= s_tile_addr;

						when others =>
							s_bkg_state <= idle;
							
					end case;
				end if;
			end if;
		end if;
	end process;
	
	s_shifter_enable <= '0' when (s_cycle > 336) or (s_cycle = 0) else '1';
	
	-- Sprites rendern

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				s_spr_read_enable <= '0';
				s_spr_fill <= -1;
				s_soa_write_enable <= '0';
			
				if i_reset_n = '0' then
					s_spr_state <= idle;
					s_spr_mem <= soa;
					s_soa_addr <= "00000";
					s_oam_addr <= x"00";
					
					for i in 0 to 7 loop
						s_sprites(i).tile_low <= x"00";
						s_sprites(i).tile_high <= x"00";
					end loop;
				else
					if s_spr_fill /= -1 then
						s_sprites(s_spr_fill).tile_high <= s_tile_data;
					end if;
					
					if s_perform_oam_access then
						s_oam_addr <= s_oam_addr + x"01";
					end if;
					
					if (s_io_state = oamaddr) and (s_io_cycle = 1) then
						s_oam_addr <= s_io_data;
					end if;
					
					-- Sprite Overflow zu Beginn eines neuen Frames zurücksetzen
					if s_prescan_line and (s_cycle = SPROVFW_CLEAR_CYCLE) then
						s_sprite_overflow <= '0';
					end if;
					
					-- OAMADDR wird bei allen sichtbaren und der Prerender-Zeile von Zyklus 257 bis 320 bei jedem Tick auf 0 gesetzt
					if s_visible_or_prescan_line and s_hblank_cycle and s_enable_rendering then
						s_oam_addr <= x"00";
					end if;
					
					case s_spr_state is

						when idle =>
							if s_visible_line and s_enable_rendering then
								s_spr_state <= clear1;
								s_soa_addr <= "00000";
								s_spr_mem <= oam;
							else
								s_spr_mem <= oam;
								s_spr_state <= wait_eol;
							end if;
							
						when clear1 =>
							s_spr_mem <= soa;
							s_soa_write_enable <= '1';
							s_spr_state <= clear2;

						when clear2 =>
							s_soa_addr <= s_soa_addr + "00001";
							s_spr_mem <= oam;

							if s_soa_addr = "11111" then
								s_spr_state <= ev_y1;
								s_new_sprite_0_visible <= false;
							else
								s_spr_state <= clear1;
							end if;
							
						when ev_y1 =>
							s_spr_mem <= soa;
							s_soa_write_enable <= '1';
							s_spr_state <= ev_y2;
							
						when ev_y2 =>
							s_spr_mem <= oam;
						
							if s_sprite_online then
								s_oam_addr <= s_oam_addr + x"01"; -- Adresse für Tile Index
								s_soa_addr <= s_soa_addr + "00001";
								s_spr_state <= ev_tile1;
								
								if s_oam_addr = x"00" then
									s_new_sprite_0_visible <= true;
								end if;
							else
								s_oam_addr <= s_oam_addr + x"04"; -- Adresse für nächste Y-Position
							
								if s_oam_addr = x"fc" then
									s_spr_state <= wait1a;
								else
									s_spr_state <= ev_y1;
								end if;
							end if;
							
						when ev_tile1 =>
							s_spr_mem <= soa;
							s_soa_write_enable <= '1';
							s_spr_state <= ev_tile2;
							
						when ev_tile2 =>
							s_spr_mem <= oam;
							s_oam_addr <= s_oam_addr + x"01"; -- Adresse für Attribute
							s_soa_addr <= s_soa_addr + "00001";
							s_spr_state <= ev_attr1;
							
						when ev_attr1 =>
							s_spr_mem <= soa;
							s_soa_write_enable <= '1';
							s_spr_state <= ev_attr2;
							
						when ev_attr2 =>
							s_spr_mem <= oam;
							s_oam_addr <= s_oam_addr + x"01"; -- Adresse für X-Position
							s_soa_addr <= s_soa_addr + "00001";
							s_spr_state <= ev_x1;
							
						when ev_x1 =>
							s_spr_mem <= soa;
							s_soa_write_enable <= '1';
							s_spr_state <= ev_x2;
							
						when ev_x2 =>
							s_spr_mem <= oam;
							s_oam_addr <= s_oam_addr + x"01"; -- Adresse für Y-Position
							s_soa_addr <= s_soa_addr + "00001";
							
							if s_soa_addr = "11111" then
								s_spr_state <= of_y1;
							elsif s_oam_addr = x"ff" then
								s_spr_state <= wait1a;
							else
								s_spr_state <= ev_y1;
							end if;
			
						when of_y1 =>
							s_spr_state <= of_y2;
							
						when of_y2 =>
							s_spr_mem <= oam;
						
							if s_sprite_online then
								s_sprite_overflow <= '1';
								s_oam_addr <= s_oam_addr + x"01"; -- Adresse für Tile Index
								s_spr_state <= of_title1;
							else
								s_spr_state <= of_y1;
							
								-- Adresse für Y-Position, Overflow-Bug: korrekt währe x"04"
								if s_oam_addr(1 downto 0) = "11" then
									s_oam_addr <= s_oam_addr + x"01";
									
									if s_oam_addr = x"ff" then
										s_spr_state <= wait1a;
									end if;
								else
									s_oam_addr <= s_oam_addr + x"05";
									
									if s_oam_addr >= x"fb" then
										s_spr_state <= wait1a;
									end if;
								end if;
							end if;
								
						when of_title1 =>
							s_spr_state <= of_title2;
							
						when of_title2 =>
							s_spr_mem <= oam;
							s_oam_addr <= s_oam_addr + x"01"; -- Adresse für Attr Index
							s_spr_state <= of_attr1;
							
						when of_attr1 =>
							s_spr_state <= of_attr2;
							
						when of_attr2 =>
							s_spr_mem <= oam;
							s_oam_addr <= s_oam_addr + x"01"; -- Adresse für X-Position
							s_spr_state <= of_x1;
							
						when of_x1 =>
							s_spr_state <= of_x2;
							
						when of_x2 =>
							s_spr_mem <= oam;
							s_oam_addr <= s_oam_addr + x"01"; -- Adresse für Y-Position
							s_spr_state <= of_y1;
							
						when wait1a =>
							s_spr_mem <= soa;
							s_spr_state <= wait1b;
						
						when wait1b =>
							s_oam_addr <= s_oam_addr + x"04";
							s_spr_mem <= oam;
							s_spr_state <= wait1a;
							
						when gf1 =>
							s_spr_state <= gf2;
							s_soa_addr <= s_soa_addr + "00001"; -- Adresse für Tile Index
						
						when gf2 =>
							s_sprite_y <= ('0' & s_ypos) - ('0' & s_soa_q); -- Y-Position
							s_spr_state <= gf3;
							s_soa_addr <= s_soa_addr + "00001"; -- Adresse für Attribute
						
						when gf3 =>
							s_sprite_tile <= s_soa_q; -- Tile Index
							s_spr_state <= gf4;
							s_soa_addr <= s_soa_addr + "00001"; -- Adresse für X-Position
						
						when gf4 =>
							s_spr_addr <= "000" & s_next_tile_addr;
							s_spr_state <= ftl1;
							s_sprites(s_spr_idx).palette <= s_soa_q(1 downto 0); -- Attribute
							s_sprites(s_spr_idx).priority <= s_soa_q(5);
							s_sprite_flip_horizontal <= s_soa_q(6);
							
						when ftl1 =>
							s_spr_state <= ftl2;
							s_sprites(s_spr_idx).x <= s_soa_q; -- X-Position
							s_spr_read_enable <= '1';
							
						when ftl2 =>
							s_spr_addr(3) <= '1'; -- +8 Bytes
							s_spr_state <= fth1;
							
						when fth1 =>
							s_sprites(s_spr_idx).tile_low <= s_tile_data;
							s_oam_addr <= x"00";
							s_spr_state <= fth2;
							s_spr_read_enable <= '1';
							
						when fth2 =>
							s_spr_fill <= s_spr_idx;
							s_spr_mem <= soa;
						
							if s_soa_addr = "11111" then
								s_spr_state <= wait_eol;
								s_soa_addr <= "00000";
							else
								s_spr_idx <= s_spr_idx + 1;
								s_spr_state <= gf1;
								s_soa_addr <= s_soa_addr + "00001"; -- Adresse für Y-Position
							end if;
							
						when wait_eol =>
							if s_last_cycle then
								if s_skip_dot then
									s_spr_state <= clear1;
									s_soa_addr <= "00000";
									s_spr_mem <= oam;
								else
									s_spr_state <= idle;
								end if;
							end if;

					end case;
					
					if s_cycle = 256 then
						s_sprite_0_visible <= s_new_sprite_0_visible;
						s_new_sprite_0_visible <= false;
					end if;
					
					if (s_cycle = 256) and (s_spr_state /= wait_eol) then
						s_spr_idx <= 0;
						s_spr_state <= gf1;
						s_soa_addr <= "00000"; -- Adresse für Y-Position
						s_spr_mem <= soa;
						
						for i in 0 to 7 loop
							s_sprites(i).tile_low <= x"00";
							s_sprites(i).tile_high <= x"00";
						end loop;
					end if;
				
				end if;
			end if;
		end if;
	end process;

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_spr_mem_d <= oam;
				else
					s_spr_mem_d <= s_spr_mem;
				end if;
			end if;
		end if;
	end process;
	
	-- VBlank
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_vblank <= '0';
				elsif s_prescan_line and (s_cycle = VBLANK_CLEAR_CYCLE) then
					s_vblank <= '0';
				elsif (s_io_state = ppustatus) and (s_io_cycle = PPUSTATUS_READ_CYCLE) then
					s_vblank <= '0'; -- VBlank zurücksetzen wenn PPUSTATUS gelesen wird
				elsif (s_line = 241) and (s_cycle = VBLANK_SET_CYCLE) then
					s_vblank <= '1';
				end if;
			end if;
		end if;
	end process;

	-- Sprite 0 Hit
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_sprite_0_hit <= '0';
				else
					if s_visible_line and (s_cycle >= 1) and (s_cycle < 256) then -- Es ist Absicht, dass hier nicht von 1 - 256 gegangen wird
						if s_sprite_0_visible and (s_sprites(0).pixel /= "00") and (s_background_pixel /= "00") then
							s_sprite_0_hit <= '1';
						end if;
					elsif s_prescan_line and (s_cycle = SPR0HIT_CLEAR_CYCLE) then
						s_sprite_0_hit <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- Ausgabe an Framebuffer
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_clk_enable = '1' then
				if i_reset_n = '0' then
					s_out_addr <= x"0000";
				elsif not s_visible_line then
					s_out_addr <= x"0000";
				elsif s_render then
					s_out_addr <= s_out_addr + x"0001";
				end if;
			end if;
		end if;
	end process;
	
	s_winning_sprite <= s_sprites(0) when s_sprites(0).pixel /= "00"
	                    else s_sprites(1) when s_sprites(1).pixel /= "00"
						 	  else s_sprites(2) when s_sprites(2).pixel /= "00"
							  else s_sprites(3) when s_sprites(3).pixel /= "00"
							  else s_sprites(4) when s_sprites(4).pixel /= "00"
							  else s_sprites(5) when s_sprites(5).pixel /= "00"
							  else s_sprites(6) when s_sprites(6).pixel /= "00"
							  else s_sprites(7) when s_sprites(7).pixel /= "00"
							  else NULL_SPRITE;
	
	s_palette_index <= '1' & s_winning_sprite.palette & s_winning_sprite.pixel when (s_winning_sprite.pixel /= "00") and (s_winning_sprite.priority = '0')
	                   else '0' & s_background_palette_index & s_background_pixel when (s_background_pixel /= "00")
							 else '1' & s_winning_sprite.palette & s_winning_sprite.pixel when (s_winning_sprite.pixel /= "00")
							 else "00000";

	s_sprite_line_test_height <= x"08" when s_big_sprites = '0' else x"10";
	s_sprite_line_lower_test <= s_ypos >= s_oam_eff_q;
	s_sprite_line_upper_test <= ('0' & s_ypos) < (('0' & s_oam_eff_q) + ('0' & s_sprite_line_test_height));
	s_sprite_online <= s_sprite_line_lower_test and s_sprite_line_upper_test;
	s_sprite_disable <= s_sprite_y(8) or s_sprite_y(7) or s_sprite_y(6) or s_sprite_y(5) or s_sprite_y(4);

	s_inner_tile_pos <= not s_sprite_y(3 downto 0) when s_soa_q(7) = '1' else s_sprite_y(3 downto 0); -- vertical flip
	s_next_tile_addr <= s_sprite_half & s_sprite_tile & '0' & s_inner_tile_pos(2 downto 0) when s_big_sprites = '0'
	                    else s_sprite_tile(0) & s_sprite_tile(7 downto 1) & s_inner_tile_pos(3) & '0' & s_inner_tile_pos(2 downto 0);
							 
	s_tile_data <= x"00" when s_sprite_disable = '1'
	               else reverse_vector(i_chr_data) when s_sprite_flip_horizontal = '1'
	               else i_chr_data;
						 
	s_video_addr <= s_spr_addr when s_visible_or_prescan_line and s_hblank_cycle and s_enable_rendering
	                else s_bkg_addr when s_visible_or_prescan_line and not s_hblank_cycle and s_enable_rendering
						 else '0' & s_vram_addr_v;
						 
	s_video_read_enable <= s_spr_read_enable when s_visible_or_prescan_line and s_hblank_cycle and s_enable_rendering
	                       else s_bkg_read_enable when s_visible_or_prescan_line and not s_hblank_cycle and s_enable_rendering
								  else '1' when (s_io_state = ppudata_read) and (s_io_cycle = 4)
								  else '0';
								  
	s_video_write_enable <= '1' when (s_io_state = ppudata_write) and (s_io_cycle = 7) and not s_palette_access else '0';
					 
	s_xpos <= std_logic_vector(to_unsigned(s_cycle - 1, 8)) when s_render else x"ff";
	s_ypos <= std_logic_vector(to_unsigned(s_line, 8));
	s_out_write_enable <= '1' when s_visible_line and s_render else '0';
	s_render <= (s_cycle >= 1) and (s_cycle < 257);
	s_visible_line <= s_line < 240;
	s_prescan_line <= s_line = s_max_line;
	s_visible_or_prescan_line <= s_visible_line or s_prescan_line;
	s_last_cycle <= s_cycle = 340;
	s_hblank_cycle <= (s_cycle > 256) and (s_cycle < 321);
	s_vram_bkg_inc <= std_logic_vector(to_unsigned(s_cycle - 1, 3)) = "110";
	s_out_color <= s_palette_color and 6x"30" when s_greyscale = '1' else s_palette_color;
	s_out_data <= s_color_emphasize & s_out_color;
	
	s_oam_write_enable <= '1' when s_perform_oam_write_access else '0';
	s_perform_oam_write_access <= (s_io_state = oamdata_write) and (s_io_cycle = 1);
	s_perform_oam_access <= s_perform_oam_write_access;
	
	s_enable_rendering <= (s_enable_background = '1') or (s_enable_sprites = '1');
	
	s_palette_quadrant <= s_vram_addr_v(6) & s_vram_addr_v(1);
	s_tile_addr <= "0010" & s_vram_addr_v(11 downto 0);
	s_attr_addr <= "0010" & s_vram_addr_v(11 downto 10) & "1111" & s_vram_addr_v(9 downto 7) & s_vram_addr_v(4 downto 2);
	s_tile_lo_addr <= "000" & s_background_half & s_tile_index & '0' & s_vram_addr_v(14 downto 12);
	s_tile_hi_addr <= "000" & s_background_half & s_tile_index & '1' & s_vram_addr_v(14 downto 12);
	s_vassign <= (s_cycle >= 280) and (s_cycle <= 304) and s_prescan_line;
	s_background_pixel <= s_th_q(s_fine_scroll_x) & s_tl_q(s_fine_scroll_x) when (s_enable_background = '1') and ((s_render_first_bkg_col = '1') or (s_xpos(7 downto 3) /= "00000")) else "00";
	s_background_palette_index <= s_bh_q(s_fine_scroll_x) & s_bl_q(s_fine_scroll_x);
	s_palette_color <= s_palette_mem(to_pal_idx(s_palette_index));
	s_palette_access <= s_vram_addr_v(14 downto 8) = 7x"3f";
	
	s_oam_data <= s_io_data(7 downto 5) & "000" & s_io_data(1 downto 0) when s_oam_addr(1 downto 0) = "10" else s_io_data;
	s_oam_eff_q <= x"ff" when (s_spr_state = clear1) or (s_spr_state = clear2) else s_oam_q;
	s_oam_clk_enable <= i_clk_enable when s_spr_mem = oam else '0';
	s_soa_clk_enable <= i_clk_enable when s_spr_mem = soa else '0';
	
	o_q <= s_q;
	o_int_n <= s_vblank nand s_enable_nmi;
	o_vga_addr <= s_out_addr;
	o_vga_data <= s_out_data;
	o_vga_write_enable <= s_out_write_enable;
	
	o_chr_addr <= s_video_addr(13 downto 0);
	o_chr_q <= s_io_data;
	o_chr_read_enable <= s_video_read_enable;
	o_chr_write_enable <= s_video_write_enable;

end architecture;
