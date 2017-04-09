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
use work.common.all;

entity nes is
	port
	(
		CLOCK_125_p : in std_logic;
		CLOCK_50_B5B : in std_logic;
		CLOCK_50_B6A : in std_logic;
		CLOCK_50_B7A : in std_logic;
		CLOCK_50_B8A : in std_logic;
		CPU_RESET_n : in std_logic;
		KEY : in std_logic_vector(3 downto 0);
		SW: in std_logic_vector(9 downto 0);
		I2C_SCL : inout std_logic;
		I2C_SDA : inout std_logic;
		GPIO : inout std_logic_vector(21 downto 0);
		LEDG : out std_logic_vector(7 downto 0);
		LEDR : out std_logic_vector(9 downto 0);
		HEX0 : out std_logic_vector(6 downto 0);
		HEX1 : out std_logic_vector(6 downto 0);
		HEX2 : out std_logic_vector(6 downto 0);
		HEX3 : out std_logic_vector(6 downto 0);
		UART_RX: in std_logic;
		UART_TX: out std_logic;
		CPU_ADDR : out std_logic_vector(14 downto 0);
		CPU_DATA : inout std_logic_vector(7 downto 0);
		CPU_DIR : out std_logic;
		CPU_RW : out std_logic;
		PPU_ADDR : out std_logic_vector(13 downto 0);
		PPU_A13_N : out std_logic;
		PPU_DATA : inout std_logic_vector(7 downto 0);
		PPU_DIR : out std_logic;
		PPU_RD_N : out std_logic;
		PPU_WR_N : out std_logic;
		ROMSEL_N : out std_logic;
		CIRAM_CE_N : in std_logic;
		CIRAM_A10 : in std_logic;
		M2 : out std_logic;
		SYS_CLK : out std_logic;
		IRQ_N : in std_logic;
		CIC_CLK : out std_logic;
		CIC_TOPAK : out std_logic;
		CIC_RST_N : out std_logic;
		CIC_TOMB : in std_logic;
		HDMI_TX_CLK : out std_logic;
		HDMI_TX_D : out std_logic_vector(23 downto 0);
		HDMI_TX_DE : out std_logic;
		HDMI_TX_HS : out std_logic;
		HDMI_TX_INT : in std_logic;
		HDMI_TX_VS : out std_logic;
		AUD_ADCDAT : in std_logic;
		AUD_ADCLRCK : inout std_logic;
		AUD_BCLK : inout std_logic;
		AUD_DACDAT : out std_logic;
		AUD_DACLRCK : inout std_logic;
		AUD_XCK : out std_logic;
		SD_CLK : out std_logic;
		SD_CMD : inout std_logic;
		SD_DAT : inout std_logic_vector(3 downto 0);
		GND : out std_logic_vector(10 downto 0)
	);
end nes;

architecture behavioral of nes is
	component master_pll is
		port
		(
			refclk : in std_logic := '0';
			rst : in std_logic := '0';
			outclk_0 : out std_logic;
			locked : out std_logic;
			reconfig_to_pll : in  std_logic_vector(63 downto 0) := (others => '0');
			reconfig_from_pll : out std_logic_vector(63 downto 0)
		);
	end component;
	component audio_pll is
		port
		(
			refclk : in std_logic := '0';
			rst : in std_logic := '0';
			outclk_0 : out std_logic;
			locked : out std_logic
		);
	end component;
	component vga_pll is
		port
		(
			refclk : in  std_logic := '0';
			rst : in std_logic := '0';
			outclk_0 : out std_logic;
			locked : out std_logic
		);
	end component;
	component nescore is
		port
		(
			i_clk : in std_logic;
			i_reset_n : in std_logic := '1';
			i_ready : in std_logic := '1';
			i_ctrl_a_data : in std_logic := '1';
			i_ctrl_b_data : in std_logic := '1';
			i_video_mode : in video_mode_t := ntsc;
			i_ciram_ce_n : in std_logic;
			i_ciram_a10 : in std_logic;
			i_prg_q : in std_logic_vector(7 downto 0);
			i_chr_q : in std_logic_vector(7 downto 0);
			i_irq_n : in std_logic := '1';
			i_rx : in std_logic := '1';
			o_tx : out std_logic;
			o_prg_addr : out std_logic_vector(14 downto 0);
			o_prg_data : out std_logic_vector(7 downto 0);
			o_prg_write_enable : out std_logic;
			o_prg_cs_n : out std_logic;
			o_chr_addr : out std_logic_vector(13 downto 0);
			o_chr_data : out std_logic_vector(7 downto 0);
			o_chr_read_enable : out std_logic;
			o_chr_write_enable : out std_logic;
			o_ctrl_strobe : out std_logic;
			o_ctrl_a_clk : out std_logic;
			o_ctrl_b_clk : out std_logic;
			o_cpu_clk_enable : out std_logic;
			o_cpu_sync : out std_logic;
			o_vga_addr : out std_logic_vector(15 downto 0);
			o_vga_data : out std_logic_vector(8 downto 0);
			o_vga_write_enable : out std_logic;
			o_vga_clk_enable : out std_logic;
			o_audio_q : out std_logic_vector(15 downto 0)
		);
	end component;
	component vga is
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
	end component;
	component i2s is
		generic
		(
			DIVIDER : natural := 4;
			WORD_WIDTH : natural := 16;
			CHANNEL_WIDTH : natural := 32
		);
		port
		(
			i_audio_clk : in std_logic;
			i_master_clk : in std_logic;
			i_clk_enable : in std_logic;
			i_audio_reset_n : in std_logic := '1';
			i_master_reset_n : in std_logic := '1';
			i_data : in std_logic_vector(WORD_WIDTH - 1 downto 0);
			o_lrclk : out std_logic;
			o_sclk : out std_logic;
			o_sdata : out std_logic
		);
	end component;
	component hex_digit is
		port
		(
			i_d : in std_logic_vector(3 downto 0);
			o_q : out std_logic_vector(6 downto 0)
		);
	end component;
	component periphery_ctrl is
		generic
		(
			CLK_SPEED : integer := 50_000_000
		);
		port
		(
			i_clk : in std_logic;
			i_reset_n : in std_logic := '1';
			i_int_n : in std_logic := '1';
			io_sda : inout std_logic;
			io_scl : inout std_logic;
			o_status : out std_logic_vector(7 downto 0);
			o_ack_error : out std_logic
		);
	end component;
	component master_reconfig is
		generic (
			ENABLE_BYTEENABLE : boolean := false;
			BYTEENABLE_WIDTH : integer := 4;
			RECONFIG_ADDR_WIDTH : integer := 6;
			RECONFIG_DATA_WIDTH : integer := 32;
			reconf_width : integer := 64
		);
		port (
			mgmt_clk : in  std_logic := '0';
			mgmt_reset : in  std_logic := '0';
			mgmt_waitrequest : out std_logic;
			mgmt_read : in  std_logic := '0';
			mgmt_write : in  std_logic := '0';
			mgmt_readdata : out std_logic_vector(31 downto 0);
			mgmt_address : in  std_logic_vector(5 downto 0) := (others => '0');
			mgmt_writedata : in  std_logic_vector(31 downto 0) := (others => '0');
			reconfig_to_pll : out std_logic_vector(63 downto 0);
			reconfig_from_pll : in  std_logic_vector(63 downto 0) := (others => '0')
		);
	end component;
	component master_ctrl is
		port
		(
			i_clk : in std_logic;
			i_reset_n : in std_logic := '1';
			i_video_mode : in video_mode_t;
			i_waitrequest : in std_logic := '0';
			i_reconfig_data : in std_logic_vector(31 downto 0) := (others => '0');
			o_video_mode : out video_mode_t;
			o_status : out std_logic_vector(7 downto 0);
			o_reconfig_read : out std_logic;
			o_reconfig_write : out std_logic;
			o_reconfig_addr : out std_logic_vector(5 downto 0);
			o_reconfig_new_data : out std_logic_vector(31 downto 0)
		);
	end component;
	component debounce is
		port
		(
			i_clk : in std_logic;
			i_in : in std_logic;
			o_q : out std_logic;
			o_riseedge : out std_logic;
			o_falledge : out std_logic
		);
	end component;
	
	alias HDMI_AUDIO_SPDIF : std_logic is GPIO(0);
	alias HDMI_AUDIO_MCLK : std_logic is GPIO(1);
	alias HDMI_AUDIO_I2S0 : std_logic is GPIO(2);
	alias HDMI_AUDIO_I2S1 : std_logic is GPIO(3);
	alias HDMI_AUDIO_I2S2 : std_logic is GPIO(4);
	alias HDMI_AUDIO_I2S3 : std_logic is GPIO(5);
	alias HDMI_AUDIO_SCLK : std_logic is GPIO(6);
	alias HDMI_AUDIO_LRCLK : std_logic is GPIO(7);
	alias CTRL_A_DATA : std_logic is GPIO(8);
	alias CTRL_B_DATA : std_logic is GPIO(9);
	alias CTRL_A_CLOCK : std_logic is GPIO(10);
	alias CTRL_B_CLOCK : std_logic is GPIO(11);
	alias CTRL_STROBE : std_logic is GPIO(12);
	
	signal s_audio_clk : std_logic;
	signal s_master_clk : std_logic;
	signal s_vga_clk : std_logic;
	signal s_reset_n : std_logic;
	signal s_audio_reset_n : std_logic;
	signal s_vga_reset_n : std_logic;
	signal s_vga_addr : std_logic_vector(15 downto 0);
	signal s_vga_data : std_logic_vector(8 downto 0);
	signal s_vga_write_enable : std_logic;
	signal s_vga_clk_enable : std_logic;
	signal s_audio_q : std_logic_vector(15 downto 0);
	signal s_debug1 : std_logic_vector(7 downto 0) := (others => '0');
	signal s_debug2 : std_logic_vector(7 downto 0) := (others => '0');
	signal s_audio_counter : integer range 0 to 62499 := 0;
	signal s_ack_error : std_logic;
	signal s_audio_lrclk : std_logic;
	signal s_audio_sclk : std_logic;
	signal s_audio_dat : std_logic;
	signal s_sample_req : std_logic_vector(1 downto 0);
	signal s_cpu_clk_enable : std_logic;
	signal s_cpu_sync : std_logic;
	signal s_prg_cs_n : std_logic;
	signal s_prg_addr : std_logic_vector(14 downto 0);
	signal s_chr_addr : std_logic_vector(13 downto 0);
	signal s_prg_data : std_logic_vector(7 downto 0);
	signal s_chr_data : std_logic_vector(7 downto 0);
	signal s_prg_write_enable : std_logic;
	signal s_chr_read_enable : std_logic;
	signal s_chr_write_enable : std_logic;
	signal s_reconfig_to_pll : std_logic_vector(63 downto 0);
	signal s_reconfig_from_pll : std_logic_vector(63 downto 0);
	signal s_reconfig_read : std_logic := '0';
	signal s_reconfig_write : std_logic := '0';
	signal s_reconfig_addr : std_logic_vector(5 downto 0) := (others => '0');
	signal s_reconfig_data : std_logic_vector(31 downto 0);
	signal s_reconfig_new_data : std_logic_vector(31 downto 0) := (others => '0');
	signal s_reconfig_waitrequest : std_logic;
	signal s_video_mode : video_mode_t;
	signal s_video_mode_configured : video_mode_t;
	signal s_key_d : std_logic_vector(3 downto 0) := (others => '1');
	signal s_debounced_vm_switch : std_logic;

begin
	master : master_pll port map
	(
		refclk => CLOCK_50_B5B,
		rst => not CPU_RESET_n,
		outclk_0 => s_master_clk,
		locked => s_reset_n,
		reconfig_to_pll => s_reconfig_to_pll,
		reconfig_from_pll => s_reconfig_from_pll
	);
	audio : audio_pll port map
	(
		refclk => CLOCK_50_B6A,
		rst => not CPU_RESET_n,
		outclk_0 => s_audio_clk,
		locked => s_audio_reset_n
	);
	vgapll : vga_pll port map
	(
		refclk => CLOCK_50_B7A,
		rst => not CPU_RESET_n,
		outclk_0 => s_vga_clk,
		locked => s_vga_reset_n
	);
	master_recfg : master_reconfig port map
	(
		mgmt_clk => CLOCK_50_B5B,
--		mgmt_reset => not CPU_RESET_n,
		mgmt_read => s_reconfig_read,
		mgmt_write => s_reconfig_write,
		mgmt_address => s_reconfig_addr,
		mgmt_readdata => s_reconfig_data,
		mgmt_writedata => s_reconfig_new_data,
		mgmt_waitrequest => s_reconfig_waitrequest,
		reconfig_to_pll => s_reconfig_to_pll,
		reconfig_from_pll => s_reconfig_from_pll
	);
	master_c : master_ctrl port map (
		i_clk => CLOCK_50_B5B,
		i_reset_n => CPU_RESET_n,
		i_video_mode => s_video_mode,
		i_waitrequest => s_reconfig_waitrequest,
		i_reconfig_data => s_reconfig_data,
		o_video_mode => s_video_mode_configured,
		o_status => s_debug2,
		o_reconfig_read => s_reconfig_read,
		o_reconfig_write => s_reconfig_write,
		o_reconfig_addr => s_reconfig_addr,
		o_reconfig_new_data => s_reconfig_new_data
	);
	nes_core : nescore port map
	(
		i_clk => s_master_clk,
		i_reset_n  => s_reset_n,
		i_ready => SW(8),
		i_ctrl_a_data => CTRL_A_DATA,
		i_ctrl_b_data => CTRL_B_DATA,
		i_video_mode => s_video_mode,
		i_ciram_ce_n => CIRAM_CE_N,
		i_ciram_a10 => CIRAM_A10,
		i_prg_q => CPU_DATA,
		i_chr_q => PPU_DATA,
		i_irq_n => IRQ_N,
		i_rx => UART_RX,
		o_tx => UART_TX,
		o_prg_addr => s_prg_addr,
		o_prg_data => s_prg_data,
		o_prg_write_enable => s_prg_write_enable,
		o_prg_cs_n => s_prg_cs_n,
		o_chr_addr => s_chr_addr,
		o_chr_data => s_chr_data,
		o_chr_read_enable => s_chr_read_enable,
		o_chr_write_enable => s_chr_write_enable,
		o_ctrl_strobe => CTRL_STROBE,
		o_ctrl_a_clk => CTRL_A_CLOCK,
		o_ctrl_b_clk => CTRL_B_CLOCK,
		o_cpu_clk_enable => s_cpu_clk_enable,
		o_cpu_sync => s_cpu_sync,
		o_vga_addr => s_vga_addr,
		o_vga_data => s_vga_data,
		o_vga_write_enable => s_vga_write_enable,
		o_vga_clk_enable => s_vga_clk_enable,
		o_audio_q => s_audio_q
	);
	vga_cmp : vga generic map
	(
		HFP => 16,
		HSYNC => 96,
		HBP => 48,
		HRES => 640,
		VFP => 10,
		VSYNC => 2,
		VBP => 33,
		VRES => 480
	)
	port map
	(
		i_data_clk => s_master_clk,
		i_data_clk_enable => s_vga_clk_enable,
		i_vga_clk => s_vga_clk,
		i_vga_clk_enable => '1',
		i_reset_n => s_vga_reset_n,
		i_addr => s_vga_addr,
		i_data => s_vga_data,
		i_write_enable => s_vga_write_enable,
		o_data_enable => HDMI_TX_DE,
		o_vsync => HDMI_TX_VS,
		o_hsync => HDMI_TX_HS,
		o_data => HDMI_TX_D
	);
	pc : periphery_ctrl port map
	(
		i_clk => CLOCK_50_B5B,
		i_reset_n => CPU_RESET_n,
		i_int_n => HDMI_TX_INT,
		io_sda => I2C_SDA,
		io_scl => I2C_SCL,
		o_status => s_debug1,
		o_ack_error => s_ack_error
	);
	i2s_cmp : i2s port map
	(
		i_audio_clk => s_audio_clk,
		i_master_clk => s_master_clk,
		i_clk_enable => s_cpu_clk_enable,
		i_audio_reset_n => s_audio_reset_n,
		i_master_reset_n => CPU_RESET_n,
		i_data => s_audio_q,
		o_lrclk => s_audio_lrclk,
		o_sclk => s_audio_sclk,
		o_sdata => s_audio_dat
	);
	hd0 : hex_digit port map
	(
		i_d => s_debug1(3 downto 0),
		o_q => HEX0
	);
	hd1 : hex_digit port map
	(
		i_d => s_debug1(7 downto 4),
		o_q => HEX1
	);
	hd2 : hex_digit port map
	(
		i_d => s_debug2(3 downto 0),
		o_q => HEX2
	);
	hd3 : hex_digit port map
	(
		i_d => s_debug2(7 downto 4),
		o_q => HEX3
	);
	deb1 : debounce port map
	(
		i_clk => CLOCK_50_B5B,
		i_in => SW(9),
		o_q => s_debounced_vm_switch
	);

	HDMI_AUDIO_MCLK <= s_audio_clk;
	HDMI_AUDIO_LRCLK <= s_audio_lrclk;
	HDMI_AUDIO_SCLK <= s_audio_sclk;
	HDMI_AUDIO_I2S0 <= s_audio_dat;
	HDMI_AUDIO_I2S1 <= '0';
	HDMI_AUDIO_I2S2 <= '0';
	HDMI_AUDIO_I2S3 <= '0';
	HDMI_AUDIO_SPDIF <= '0';
	AUD_DACDAT <= s_audio_dat;
	AUD_XCK <= s_audio_clk;
	AUD_DACLRCK <= s_audio_lrclk;
	AUD_BCLK <= s_audio_sclk;
	HDMI_TX_CLK <= s_vga_clk;
	LEDR(9) <= '1' when s_video_mode_configured = pal else '0';
	LEDR(8) <= s_reconfig_waitrequest;
	LEDR(7) <= not HDMI_TX_INT;
	LEDR(6) <= s_ack_error;
	LEDR(5 downto 0) <= (others => '0');
	LEDG <= (others => '0');
	CTRL_A_DATA <= 'Z';
	CTRL_B_DATA <= 'Z';
	
	CIC_CLK <= '0';
	CIC_TOPAK <= '0';
	CIC_RST_N <= '1';
	SYS_CLK <= '0'; -- s_master_clk
	M2 <= s_cpu_sync;
	GND <= (others => '0');
	
	ROMSEL_N <= s_prg_cs_n;
	CPU_ADDR <= s_prg_addr;
	CPU_DATA <= s_prg_data when s_prg_write_enable = '1' else (others => 'Z');
	CPU_DIR <= s_prg_write_enable;
	CPU_RW <= not s_prg_write_enable;
	PPU_ADDR <= s_chr_addr;
	PPU_DATA <= s_chr_data when s_chr_write_enable = '1' else (others => 'Z');
	PPU_DIR <= s_chr_write_enable;
	PPU_RD_N <= not s_chr_read_enable;
	PPU_WR_N <= not s_chr_write_enable;
	PPU_A13_N <= not s_chr_addr(13);
	
	s_video_mode <= ntsc when s_debounced_vm_switch = '0' else pal;
	
end;


/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity nescore is
	port
	(
		i_clk : in std_logic;
		i_reset_n : in std_logic := '1';
		i_ready : in std_logic := '1';
		i_ctrl_a_data : in std_logic := '1';
		i_ctrl_b_data : in std_logic := '1';
		i_video_mode : in video_mode_t := ntsc;
		i_ciram_ce_n : in std_logic := '1';
		i_ciram_a10 : in std_logic := '0';
		i_prg_q : in std_logic_vector(7 downto 0);
		i_chr_q : in std_logic_vector(7 downto 0);
		i_irq_n : in std_logic := '1';
		i_rx : in std_logic := '1';
		o_tx : out std_logic;
		o_prg_addr : out std_logic_vector(14 downto 0);
		o_prg_data : out std_logic_vector(7 downto 0);
		o_prg_write_enable : out std_logic;
		o_prg_cs_n : out std_logic;
		o_chr_addr : out std_logic_vector(13 downto 0);
		o_chr_data : out std_logic_vector(7 downto 0);
		o_chr_read_enable : out std_logic;
		o_chr_write_enable : out std_logic;
		o_ctrl_strobe : out std_logic;
		o_ctrl_a_clk : out std_logic;
		o_ctrl_b_clk : out std_logic;
		o_cpu_clk_enable : out std_logic;
		o_cpu_sync : out std_logic;
		o_vga_addr : out std_logic_vector(15 downto 0);
		o_vga_data : out std_logic_vector(8 downto 0);
		o_vga_write_enable : out std_logic;
		o_vga_clk_enable : out std_logic;
		o_audio_q : out std_logic_vector(15 downto 0)
	);
end nescore;

architecture behavioral of nescore is
	component cpu is
		port
		(
			i_clk : in std_logic;
			i_clk_p_enable : in std_logic := '1';
			i_clk_n_enable : in std_logic := '0';
			i_ready : in std_logic := '1';
			i_reset_n : in std_logic := '1';
			i_int_n : in std_logic := '1';
			i_nmi_n : in std_logic := '1';
			i_mem_q : in std_logic_vector(7 downto 0) := x"00";
			o_mem_addr : out std_logic_vector(15 downto 0);
			o_mem_data : out std_logic_vector(7 downto 0);
			o_mem_write_enable : out std_logic
		);
	end component;
	component ppu is
		port
		(
			i_clk: in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n: in std_logic := '1';
			i_video_mode : in video_mode_t := ntsc;
			i_addr : in std_logic_vector(2 downto 0) := "000";
			i_data : in std_logic_vector(7 downto 0) := x"00";
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '0';
			i_chr_data : in std_logic_vector(7 downto 0) := x"00";
			o_q : out std_logic_vector(7 downto 0);
			o_int_n : out std_logic;
			o_vga_addr: out std_logic_vector(15 downto 0);
			o_vga_data: out std_logic_vector(8 downto 0);
			o_vga_write_enable: out std_logic;
			o_chr_addr : out std_logic_vector(13 downto 0);
			o_chr_read_enable : out std_logic;
			o_chr_write_enable : out std_logic;
			o_chr_q : out std_logic_vector(7 downto 0)
		);
	end component;
	component apu is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic;
			i_reset_n : in std_logic := '1';
			i_addr : in std_logic_vector(4 downto 0) := 5x"00";
			i_data : in std_logic_vector(7 downto 0) := x"00";
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			i_dma_write_enable : in std_logic := '0';
			i_dma_q : in std_logic_vector(7 downto 0) := x"00";
			i_ctrl_a_data : in std_logic := '1';
			i_ctrl_b_data : in std_logic := '1';
			i_video_mode : in video_mode_t := ntsc;
			o_ctrl_strobe : out std_logic;
			o_ctrl_a_clk : out std_logic;
			o_ctrl_b_clk : out std_logic;
			o_int_n : out std_logic;
			o_audio : out std_logic_vector(15 downto 0);
			o_q : out std_logic_vector(7 downto 0);
			o_dma_addr : out std_logic_vector(15 downto 0);
			o_dma_data : out std_logic_vector(7 downto 0);
			o_dma_write_enable : out std_logic;
			o_dma_ready : out std_logic;
			o_dma_active : out std_logic
		);
	end component;
	component peripherial_io is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n : in std_logic;
			i_addr : in std_logic_vector(2 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic;
			i_cs_n : in std_logic := '1';
			i_rx : in std_logic := '1';
			o_tx : out std_logic;
			o_q : out std_logic_vector(7 downto 0)
		);
	end component;
	component data_path is
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
			i_pio_q : in std_logic_vector(7 downto 0);
			o_prg_addr : out std_logic_vector(14 downto 0);
			o_prg_cs_n : out std_logic;
			o_ppu_addr : out std_logic_vector(2 downto 0);
			o_ppu_cs_n : out std_logic;
			o_apu_addr : out std_logic_vector(4 downto 0);
			o_apu_cs_n : out std_logic;
			o_pio_addr : out std_logic_vector(2 downto 0);
			o_pio_cs_n : out std_logic;
			o_q : out std_logic_vector(7 downto 0)
		);
	end component;
	component videomem is
		port
		(
			address : in std_logic_vector(10 downto 0);
			clken : in std_logic := '1';
			clock : in std_logic := '1';
			data : in std_logic_vector(7 downto 0);
			rden : in std_logic := '0';
			wren : in std_logic := '0';
			q : out std_logic_vector(7 downto 0)
		);
	end component;
	
	signal s_cpu_clk_p_enable : std_logic;
	signal s_cpu_clk_n_enable : std_logic;
	signal s_cpu_sync : std_logic;
	signal s_ppu_q : std_logic_vector(7 downto 0);
	signal s_ppu_addr : std_logic_vector(2 downto 0);
	signal s_ppu_cs_n : std_logic;
	signal s_apu_addr : std_logic_vector(4 downto 0);
	signal s_apu_cs_n : std_logic;
	signal s_apu_int_n : std_logic;
	signal s_apu_q : std_logic_vector(7 downto 0);
	signal s_nmi_n : std_logic;
	signal s_int_n : std_logic;
	signal s_mem_q : std_logic_vector(7 downto 0);
	signal s_mem_addr : std_logic_vector(15 downto 0);
	signal s_mem_data : std_logic_vector(7 downto 0);
	signal s_mem_write_enable : std_logic;
	signal s_eff_addr : std_logic_vector(15 downto 0);
	signal s_eff_data : std_logic_vector(7 downto 0);
	signal s_eff_write_enable : std_logic;
	signal s_dma_addr : std_logic_vector(15 downto 0);
	signal s_dma_data : std_logic_vector(7 downto 0);
	signal s_dma_write_enable : std_logic;
	signal s_dma_ready : std_logic;
	signal s_dma_active : std_logic;
	signal s_chr_addr : std_logic_vector(13 downto 0);
	signal s_chr_q : std_logic_vector(7 downto 0);
	signal s_chr_data : std_logic_vector(7 downto 0);
	signal s_chr_latch : std_logic_vector(7 downto 0) := (others => '0');
	signal s_chr_read_enable : std_logic;
	signal s_chr_write_enable : std_logic;
	signal s_ppu_clk_enable : std_logic;
	signal s_ciram_ce_d : std_logic_vector(1 downto 0) := "00";
	signal s_ciram_a10_d : std_logic := '0';
	signal s_ciram_q : std_logic_vector(7 downto 0);
	signal s_chr_eff_q : std_logic_vector(7 downto 0);
	signal s_prg_q : std_logic_vector(7 downto 0) := (others => '0');
	signal s_prg_latch : std_logic_vector(7 downto 0) := (others => '0');
	signal s_cpu_divider : natural range 0 to 31 := 31;
	signal s_ppu_divider : natural range 0 to 31 := 31;
	signal s_cpu_middle : natural range 0 to 31 := 31;
	signal s_cpu_counter : natural range 0 to 31 := 0;
	signal s_ppu_counter : natural range 0 to 31 := 0;
	signal s_sync_start : natural range 0 to 31 := 0;
	signal s_sync_stop : natural range 0 to 31 := 0;
	signal s_next_cpu_divider : natural range 0 to 31;
	signal s_next_ppu_divider : natural range 0 to 31;
	signal s_next_sync_start : natural range 0 to 31;
	signal s_next_sync_stop : natural range 0 to 31;
	signal s_last_cpu_cycle : boolean;
	signal s_mid_cpu_cycle : boolean;
	signal s_last_ppu_cycle : boolean;
	signal s_pio_q : std_logic_vector(7 downto 0);
	signal s_pio_addr : std_logic_vector(2 downto 0);
	signal s_pio_cs_n : std_logic;
	
begin

	cpu_core : cpu port map
	(
		i_clk => i_clk,
		i_clk_p_enable => s_cpu_clk_p_enable,
		i_clk_n_enable => s_cpu_clk_n_enable,
		i_ready => s_dma_ready and i_ready,
		i_reset_n => i_reset_n,
		i_nmi_n => s_nmi_n,
		i_int_n => s_int_n,
		i_mem_q => s_mem_q,
		o_mem_addr => s_mem_addr,
		o_mem_data => s_mem_data,
		o_mem_write_enable => s_mem_write_enable
	);
	ppu_cmp : ppu port map
	(
		i_clk => i_clk,
		i_clk_enable => s_ppu_clk_enable,
		i_reset_n => i_reset_n,
		i_video_mode => i_video_mode,
		i_addr => s_ppu_addr,
		i_data => s_eff_data,
		i_write_enable => s_eff_write_enable,
		i_cs_n => s_ppu_cs_n,
		i_chr_data => s_chr_q,
		o_q => s_ppu_q,
		o_int_n => s_nmi_n,
		o_vga_addr => o_vga_addr,
		o_vga_data => o_vga_data,
		o_vga_write_enable => o_vga_write_enable,
		o_chr_addr => s_chr_addr,
		o_chr_q => s_chr_data,
		o_chr_read_enable => s_chr_read_enable,
		o_chr_write_enable => s_chr_write_enable
	);
	apu_core : apu port map
	(
		i_clk => i_clk,
		i_clk_enable => s_cpu_clk_p_enable,
		i_reset_n => i_reset_n,
		i_addr => s_apu_addr,
		i_data => s_eff_data,
		i_write_enable => s_eff_write_enable,
		i_cs_n => s_apu_cs_n,
		i_ctrl_a_data => i_ctrl_a_data,
		i_ctrl_b_data => i_ctrl_b_data,
		i_dma_write_enable => s_mem_write_enable,
		i_dma_q => s_mem_q,
		i_video_mode => i_video_mode,
		o_ctrl_strobe => o_ctrl_strobe,
		o_ctrl_a_clk => o_ctrl_a_clk,
		o_ctrl_b_clk => o_ctrl_b_clk,
		o_int_n => s_apu_int_n,
		o_audio => o_audio_q,
		o_q => s_apu_q,
		o_dma_addr => s_dma_addr,
		o_dma_data => s_dma_data,
		o_dma_write_enable => s_dma_write_enable,
		o_dma_ready => s_dma_ready,
		o_dma_active => s_dma_active
	);
	/*
	pio_core : peripherial_io port map
	(
		i_clk => i_clk,
		i_clk_enable => s_cpu_clk_enable,
		i_reset_n => i_reset_n,
		i_addr => s_pio_addr,
		i_data => s_eff_data,
		i_write_enable => s_eff_write_enable,
		i_cs_n => s_pio_cs_n,
		i_rx => i_rx,
		o_tx => o_tx,
		o_q => s_pio_q
	);
	*/
	dpath : data_path port map
	(
		i_clk => i_clk,
		i_clk_enable => s_cpu_clk_p_enable,
		i_sync => s_cpu_sync,
		i_reset_n => i_reset_n,
		i_addr => s_eff_addr,
		i_data => s_eff_data,
		i_write_enable => s_eff_write_enable,
		i_ppu_q => s_ppu_q,
		i_apu_q => s_apu_q,
		i_prg_q => s_prg_q,
		i_pio_q => s_pio_q,
		o_prg_addr => o_prg_addr,
		o_prg_cs_n => o_prg_cs_n,
		o_ppu_addr => s_ppu_addr,
		o_ppu_cs_n => s_ppu_cs_n,
		o_apu_addr => s_apu_addr,
		o_apu_cs_n => s_apu_cs_n,
		o_pio_addr => s_pio_addr,
		o_pio_cs_n => s_pio_cs_n,
		o_q => s_mem_q
	);
	ciram : videomem port map
	(
		clock => i_clk,
		address => s_ciram_a10_d & s_chr_addr(9 downto 0),
		clken => s_ppu_clk_enable and s_ciram_ce_d(0),
		data => s_chr_data,
		rden => s_chr_read_enable,
		wren => s_chr_write_enable,
		q => s_ciram_q
	);
	
	process (i_video_mode)
	begin
		case i_video_mode is
		
			when ntsc =>
				s_next_cpu_divider <= 12;
				s_next_ppu_divider <= 4;
				s_next_sync_start <= 1;
				s_next_sync_stop <= 10;
				
			when pal =>
				s_next_cpu_divider <= 16;
				s_next_ppu_divider <= 5;
				s_next_sync_start <= 2;
				s_next_sync_stop <= 14;
			
		end case;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if (i_reset_n = '0') or (s_last_cpu_cycle and s_last_ppu_cycle) then
				s_cpu_divider <= s_next_cpu_divider;
				s_cpu_middle <= s_next_cpu_divider / 2;
				s_ppu_divider <= s_next_ppu_divider;
				s_sync_start <= s_next_sync_start;
				s_sync_stop <= s_next_sync_stop;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_last_cpu_cycle then
				s_cpu_counter <= 0;
			else
				s_cpu_counter <= s_cpu_counter + 1;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_last_ppu_cycle then
				s_ppu_counter <= 0;
			else
				s_ppu_counter <= s_ppu_counter + 1;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_cpu_counter = s_sync_stop then
				s_cpu_sync <= '0';
			elsif s_cpu_counter = s_sync_start then
				s_cpu_sync <= '1';
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_prg_q <= (others => '0');
			elsif s_last_cpu_cycle then
				s_prg_q <= i_prg_q;
			else
				s_prg_q <= s_prg_latch;
			end if;
		end if;
	end process;

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_prg_latch <= (others => '0');
			elsif s_cpu_counter = s_sync_stop then
				s_prg_latch <= i_prg_q;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_ciram_a10_d <= '0';
			elsif s_ppu_clk_enable = '1' then
				s_ciram_a10_d <= i_ciram_a10;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_ciram_ce_d <= (others => '0');
			elsif s_ppu_clk_enable = '1' then
				s_ciram_ce_d <= s_ciram_ce_d(0) & not i_ciram_ce_n;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_chr_latch <= (others => '0');
			elsif s_ppu_clk_enable = '1' then
				s_chr_latch <= i_chr_q;
			end if;
		end if;
	end process;
	
	s_last_cpu_cycle <= s_cpu_counter = s_cpu_divider - 1;
	s_mid_cpu_cycle <= s_cpu_counter = s_cpu_middle - 1;
	s_last_ppu_cycle <= s_ppu_counter = s_ppu_divider - 1;
	
	s_cpu_clk_p_enable <= '1' when s_last_cpu_cycle else '0';
	s_cpu_clk_n_enable <= '1' when s_mid_cpu_cycle else '0';
	s_ppu_clk_enable <= '1' when s_last_ppu_cycle else '0';
	
	s_eff_write_enable <= s_dma_write_enable when s_dma_active = '1' else s_mem_write_enable;
	s_eff_addr <= s_dma_addr when s_dma_active = '1' else s_mem_addr;
	s_eff_data <= s_dma_data when s_dma_active = '1' else s_mem_data;
	
	s_int_n <= s_apu_int_n and i_irq_n;
	s_chr_q <= s_ciram_q when s_ciram_ce_d(1) = '1' else s_chr_latch;

	o_cpu_clk_enable <= s_cpu_clk_p_enable;
	o_cpu_sync <= s_cpu_sync;
	o_vga_clk_enable <= s_ppu_clk_enable;
	o_chr_addr <= s_chr_addr;
	o_chr_data <= s_chr_data;
	o_chr_read_enable <= s_chr_read_enable;
	o_chr_write_enable <= s_chr_write_enable;
	o_prg_data <= s_eff_data;
	o_prg_write_enable <= s_eff_write_enable;
	
end;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity nestest is
	port
	(
		i_clk : in std_logic;
		i_reset_n : in std_logic := '1'
	);
end nestest;

architecture behavioral of nestest is
	component nescore is
		port
		(
			i_clk : in std_logic;
			i_reset_n : in std_logic := '1';
			i_ready : in std_logic := '1';
			i_ctrl_a_data : in std_logic := '1';
			i_ctrl_b_data : in std_logic := '1';
			i_video_mode : in video_mode_t := ntsc;
			i_ciram_ce_n : in std_logic := '1';
			i_ciram_a10 : in std_logic := '0';
			i_prg_q : in std_logic_vector(7 downto 0);
			i_chr_q : in std_logic_vector(7 downto 0);
			i_irq_n : in std_logic := '1';
			i_rx : in std_logic := '1';
			o_tx : out std_logic;
			o_prg_addr : out std_logic_vector(14 downto 0);
			o_prg_data : out std_logic_vector(7 downto 0);
			o_prg_write_enable : out std_logic;
			o_prg_cs_n : out std_logic;
			o_chr_addr : out std_logic_vector(13 downto 0);
			o_chr_data : out std_logic_vector(7 downto 0);
			o_chr_read_enable : out std_logic;
			o_chr_write_enable : out std_logic;
			o_ctrl_strobe : out std_logic;
			o_ctrl_a_clk : out std_logic;
			o_ctrl_b_clk : out std_logic;
			o_cpu_clk_enable : out std_logic;
			o_cpu_sync : out std_logic;
			o_vga_addr : out std_logic_vector(15 downto 0);
			o_vga_data : out std_logic_vector(8 downto 0);
			o_vga_write_enable : out std_logic;
			o_vga_clk_enable : out std_logic;
			o_audio_q : out std_logic_vector(15 downto 0)
		);
	end component;
	component progmem is
		port
		(
			address : in std_logic_vector(14 downto 0);
			clken : in std_logic := '1';
			clock : in std_logic := '1';
			data : in std_logic_vector(7 downto 0);
			wren : in std_logic;
			q : out std_logic_vector(7 downto 0)
		);
	end component;
	component videorom is
		port
		(
			address : in std_logic_vector(12 downto 0);
			clken : in std_logic := '1';
			clock : in std_logic := '1';
			data : in std_logic_vector(7 downto 0);
			rden : in std_logic := '0';
			wren : in std_logic := '0';
			q : out std_logic_vector(7 downto 0)
		);
	end component;
	
	signal s_prg_addr : std_logic_vector(14 downto 0);
	signal s_prg_q : std_logic_vector(7 downto 0);
	signal s_prg_data : std_logic_vector(7 downto 0);
	signal s_prg_write_enable : std_logic;
	signal s_prg_eff_q : std_logic_vector(7 downto 0);
	signal s_prg_cs_n : std_logic;
	signal s_chr_addr : std_logic_vector(13 downto 0);
	signal s_chr_data : std_logic_vector(7 downto 0);
	signal s_chr_read_enable : std_logic;
	signal s_chr_write_enable : std_logic;
	signal s_chr_q : std_logic_vector(7 downto 0);
	signal s_chr_eff_q : std_logic_vector(7 downto 0);
	signal s_init_counter : natural := 16;
	signal s_init : std_logic;
	signal s_reset_n : std_logic;

begin

	nes_core : nescore port map
	(
		i_clk => i_clk,
		i_reset_n => s_reset_n,
		i_prg_q => s_prg_eff_q,
		i_chr_q => s_chr_q,
		i_ciram_ce_n => not s_chr_addr(13),
		i_ciram_a10 => s_chr_addr(10),
		i_video_mode => pal,
		o_prg_addr => s_prg_addr,
		o_prg_data => s_prg_data,
		o_prg_write_enable => s_prg_write_enable,
		o_prg_cs_n => s_prg_cs_n,
		o_chr_addr => s_chr_addr,
		o_chr_data => s_chr_data,
		o_chr_read_enable => s_chr_read_enable,
		o_chr_write_enable => s_chr_write_enable
	);
	prgrom : progmem port map
	(
		address => s_prg_addr,
		clken => not s_prg_cs_n,
		clock => i_clk,
		data => s_prg_data,
		wren => s_prg_write_enable,
		q => s_prg_q
	);
	chrrom : videorom port map
	(
		address => s_chr_addr(12 downto 0),
		clken => '1',
		clock => i_clk,
		data => s_chr_data,
		rden => s_chr_read_enable,
		wren => s_chr_write_enable,
		q => s_chr_q
	);
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_init_counter /= 0 then
				s_init_counter <= s_init_counter - 1;
			end if;
		end if;
	end process;
	
	s_init <= '1' when s_init_counter = 0 else '0';
	s_reset_n <= i_reset_n and s_init;
	s_prg_eff_q <= s_prg_q when s_prg_cs_n = '0' else (others => 'Z');
	s_chr_eff_q <= s_chr_q when s_chr_read_enable = '1' else (others => 'Z');

end;
