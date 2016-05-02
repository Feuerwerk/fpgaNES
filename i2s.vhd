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
	constant HALF_DIVIDER : natural := DIVIDER / 2;
	
	signal s_clk_divider : natural range 0 to DIVIDER - 1 := 0;
	signal s_sdata : std_logic;
	signal s_sclk : std_logic := '0';
	signal s_buffer : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
	signal s_data : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
	signal s_bit_index : natural range 0 to CHANNEL_WIDTH - 1 := 0;
	signal s_lrclk : std_logic := '1';
	signal s_sclk_sync : std_logic_vector(1 downto 0) := "00";
	signal s_audio_fq1 : std_logic_vector(15 downto 0);
	signal s_audio_fq2 : std_logic_vector(15 downto 0);
	signal s_audio_fq3 : std_logic_vector(15 downto 0);
	signal s_falling_sclk : std_logic;
	signal s_sample_last : std_logic;
	
begin

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
			if s_falling_sclk = '1' then
				if s_sample_last = '1' then
					s_bit_index <= 0;
					s_lrclk <= not s_lrclk;
					
					if i_clk_enable = '1' then
						s_buffer <= i_data;
					else
						s_buffer <= s_data;
					end if;
				else
					s_bit_index <= s_bit_index + 1;
					s_buffer <= s_buffer(WORD_WIDTH - 2 downto 0) & '0';
				end if;
			end if;
			
			if i_clk_enable = '1' then
				s_data <= i_data;
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
