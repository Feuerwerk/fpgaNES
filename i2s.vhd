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

-- this component will output a left aligned 16 bit audio sample with 44.1 kHz over an I2S connection
-- while SCLK and MCLK is driven by its own clock the audio sample itself comes from the master clock domain
-- and has to be synched with the audio clock

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s is
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
end i2s;

architecture behavioral of i2s is
	component biquad is
		generic
		(
			B0 : std_logic_vector(31 downto 0);
			B1 : std_logic_vector(31 downto 0);
			B2 : std_logic_vector(31 downto 0);
			A1 : std_logic_vector(31 downto 0);
			A2 : std_logic_vector(31 downto 0)
		);
		port
		( 
			i_clk : in std_logic;
			i_reset_n : in std_logic := '1';
			i_sample_trig : in std_logic;
			i_x : in std_logic_vector(17 downto 0);
			o_filter_done : out std_logic;
			o_q : out std_logic_vector(17 downto 0)
		);
	end component;

	constant HALF_DIVIDER : natural := DIVIDER / 2;
	
	signal s_clk_divider : natural range 0 to DIVIDER - 1 := 0;
	signal s_sdata : std_logic;
	signal s_sclk : std_logic := '0';
	signal s_buffer : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
	signal s_data : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
	signal s_bit_index : natural range 0 to CHANNEL_WIDTH - 1 := 0;
	signal s_lrclk : std_logic := '1';
	signal s_sclk_sync : std_logic_vector(1 downto 0) := "00";
	signal s_falling_sclk : std_logic;
	signal s_sample_last : std_logic;
	signal s_bq_low_done : std_logic;
	signal s_bq_high90_done : std_logic;
	signal s_bq_high440_done : std_logic;
	signal s_bq_high90_q : std_logic_vector(17 downto 0);
	signal s_bq_high440_q : std_logic_vector(17 downto 0);
	signal s_bq_low_q : std_logic_vector(17 downto 0);
	
begin

	-- Low-Pass 1st Order: fs= 44.1kHz, fc = 14.0 kHz
	bq_low : biquad generic map
	(
		B0 => B"00_10_0110_1110_0010_1001_1111_0111_0101",				--  0.607581963
		B1 => B"00_10_0110_1110_0010_1001_1111_0111_0101",				--  0.607581963
		B2 => B"00_00_0000_0000_0000_0000_0000_0000_0000",				--  0.0	
		A1 => B"00_00_1101_1100_0101_0011_1110_1110_1010",				--  0.215163926
		A2 => B"00_00_0000_0000_0000_0000_0000_0000_0000"				--  0.0
	)
	port map
	(
		i_clk => i_master_clk,
		i_sample_trig => s_falling_sclk and s_sample_last,
		i_reset_n => i_master_reset_n,
		i_x => "00" & i_data,
		o_filter_done => s_bq_low_done,
		o_q => s_bq_low_q
	);
	
	-- High-Pass 1st Order: fs= 44.1kHz, fc = 440 Hz
	bq_high440 : biquad generic map
	(
		B0 => B"00_11_1110_0000_1101_1110_0101_1111_1001",				--  0.969598287
		B1 => B"11_00_0001_1111_0010_0001_1010_0000_0111",				-- -0.969598287
		B2 => B"00_00_0000_0000_0000_0000_0000_0000_0000",				--  0.0	
		A1 => B"11_00_0011_1110_0100_0011_0100_0000_1111",				-- -0,939196573
		A2 => B"00_00_0000_0000_0000_0000_0000_0000_0000"				--  0.0
	)
	port map
	(
		i_clk => i_master_clk,
		i_sample_trig => s_bq_low_done,
		i_reset_n => i_master_reset_n,
		i_x => s_bq_low_q,
		o_filter_done => s_bq_high440_done,
		o_q => s_bq_high440_q
	);

	-- High-Pass 1st Order: fs= 44.1kHz, fc = 90 Hz
	bq_high90 : biquad generic map
	(
		B0 => B"00_11_1111_1001_0111_1001_1111_1000_1000",				--  0.993629344
		B1 => B"11_00_0000_0110_1000_0110_0000_0111_1000",				-- -0.993629344
		B2 => B"00_00_0000_0000_0000_0000_0000_0000_0000",				--  0.0	
		A1 => B"11_00_0000_1101_0000_1100_0000_1111_0000",				-- -0.987258688
		A2 => B"00_00_0000_0000_0000_0000_0000_0000_0000"				--  0.0
	)
	port map
	(
		i_clk => i_master_clk,
		i_sample_trig => s_bq_high440_done,
		i_reset_n => i_master_reset_n,
		i_x => s_bq_high440_q,
		o_filter_done => s_bq_high90_done,
		o_q => s_bq_high90_q
	);

	-- Clock Divider
	
	process (i_audio_clk)
	begin
		if rising_edge(i_audio_clk) then
			if i_audio_reset_n = '0' then
				s_clk_divider <= 0;
				s_sclk <= '0';
			else
				if s_clk_divider = DIVIDER - 1 then
					s_clk_divider <= 0;
				else
					s_clk_divider <= s_clk_divider + 1;
				end if;
				
				if s_clk_divider = DIVIDER - 1 then
					s_sclk <= '1';
				elsif s_clk_divider = HALF_DIVIDER - 1 then
					s_sclk <= '0';
				end if;
				
			end if;
		end if;
	end process;
	
	-- Bit-Stream

	process (i_master_clk)
	begin
		if rising_edge(i_master_clk) then
			if s_bq_low_done = '1' then
				s_data <= s_bq_low_q(15 downto 0);
			end if;
		
			if s_falling_sclk = '1' then
				if s_sample_last = '1' then
					s_bit_index <= 0;
					s_lrclk <= not s_lrclk;
					s_buffer <= s_data;
				else
					s_bit_index <= s_bit_index + 1;
					s_buffer <= s_buffer(WORD_WIDTH - 2 downto 0) & '0';
				end if;
			end if;

			s_sclk_sync <= s_sclk_sync(0) & s_sclk; -- SCLK Synchronization Chain
		end if;
	end process;
	
	s_falling_sclk <= s_sclk_sync(1) and not s_sclk_sync(0); -- SCLK falling edge
	s_sample_last <= '1' when s_bit_index = CHANNEL_WIDTH - 1 else '0';
	
	o_lrclk <= s_lrclk;
	o_sclk <= s_sclk;
	o_sdata <= s_buffer(WORD_WIDTH - 1);

end behavioral;
