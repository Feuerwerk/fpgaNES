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

entity envelope is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic := '1';
		i_reset_n : in std_logic := '1';
		i_reload : in boolean := false;
		i_loop : in std_logic := '0';
		i_disable : in std_logic := '1';
		i_volume : in std_logic_vector(3 downto 0) := "0000";
		o_q : out std_logic_vector(3 downto 0)
	);
end envelope;

architecture behavioral of envelope is
	signal s_counter : std_logic_vector(3 downto 0) := (others => '1');
	signal s_divider : std_logic_vector(3 downto 0) := (others => '0');
begin

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_divider <= (others => '0');
				s_counter <= (others => '1');
			elsif i_clk_enable = '1' then
				if i_reload then
					s_divider <= i_volume;
					s_counter <= (others => '1');
				elsif s_divider /= "0000" then
					s_divider <= s_divider - "0001";
				else
					s_divider <= i_volume;
					
					if s_counter /= "0000" then
						s_counter <= s_counter - "0001";
					elsif i_loop = '1' then
						s_counter <= (others => '1');
					end if;
				end if;
			end if;
		end if;
	end process;
	
	o_q <= i_volume when i_disable = '1' else s_counter;

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity length_counter is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic := '1';
		i_reset_n : in std_logic := '1';
		i_lcounter_clk : in std_logic := '1';
		i_channel_enable : in std_logic := '1';
		i_channel_reload : in std_logic := '0';
		i_enable : in std_logic := '1';
		i_addr : in std_logic_vector(1 downto 0);
		i_data : in std_logic_vector(7 downto 0);
		i_write_enable : in std_logic := '0';
		i_cs_n : in std_logic := '1';
		o_active : out std_logic
	);
end length_counter;

architecture behavioral of length_counter is

	type length_counter_t is array (0 to 31) of std_logic_vector(7 downto 0);
	
	constant LENGTH_COUNTER_TABLE : length_counter_t := ( x"0A", x"FE", x"14", x"02", x"28", x"04", x"50", x"06", x"A0", x"08", x"3C", x"0A", x"0E", x"0C", x"1A", x"0E",
																			x"0C", x"10", x"18", x"12", x"30", x"14", x"60", x"16", x"C0", x"18", x"48", x"1A", x"10", x"1C", x"20", x"1E" );

	signal s_length_active : boolean;
	signal s_length_counter : std_logic_vector(7 downto 0) := x"00";
begin

	process (i_clk)
		variable length_index : integer range 0 to 31;
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_length_counter <= x"00";
			elsif i_clk_enable = '1' then
				if (i_cs_n = '0') and (i_write_enable = '1') and (i_addr = "11") and (i_channel_enable = '1') and ((i_lcounter_clk = '0') or (s_length_counter = x"00")) then
					length_index := to_integer(unsigned(i_data(7 downto 3)));
					s_length_counter <= LENGTH_COUNTER_TABLE(length_index);
				elsif (i_channel_reload = '1') and (i_channel_enable = '0') then
					s_length_counter <= x"00";
				elsif (i_lcounter_clk = '1') and s_length_active and (i_enable = '1') then
					s_length_counter <= s_length_counter - x"01";
				end if;
			end if;
		end if;
	end process;

	s_length_active <= s_length_counter /= x"00";
	o_active <= '1' when s_length_active else '0';

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity square_channel is
	generic
	(
		INCREMENT : std_logic := '0'
	);
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic;
		i_reset_n : in std_logic := '1';
		i_apu_clk : in std_logic;
		i_envelope_clk : in std_logic := '1';
		i_lcounter_clk : in std_logic := '1';
		i_addr : in std_logic_vector(1 downto 0);
		i_data : in std_logic_vector(7 downto 0);
		i_write_enable : in std_logic := '0';
		i_cs_n : in std_logic := '1';
		i_enable : in std_logic := '0';
		i_reload : in std_logic := '0';
		o_active : out std_logic;
		o_q : out std_logic_vector(3 downto 0)
	);
end square_channel;

architecture behavioral of square_channel is
	component envelope is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n : in std_logic := '1';
			i_reload : in boolean := false;
			i_loop : in std_logic := '0';
			i_disable : in std_logic := '1';
			i_volume : in std_logic_vector(3 downto 0) := "0000";
			o_q : out std_logic_vector(3 downto 0)
		);
	end component;
	component length_counter is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n : in std_logic := '1';
			i_lcounter_clk : in std_logic := '1';
			i_channel_enable : in std_logic := '1';
			i_channel_reload : in std_logic := '0';
			i_enable : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			o_active : out std_logic
		);
	end component;

	type duty_table_t is array (0 to 31) of std_logic;
	constant DUTY_TABLE : duty_table_t := ( '0', '0', '0', '0', '0', '0', '0', '1',
	                                        '0', '0', '0', '0', '0', '0', '1', '1',
														 '0', '0', '0', '0', '1', '1', '1', '1',
														 '1', '1', '1', '1', '1', '1', '0', '0' );

	signal s_duty : std_logic_vector(1 downto 0) := "00";
	signal s_envelope_reload : boolean := false;
	signal s_envelope_loop : std_logic := '0';
	signal s_envelope_disable : std_logic := '1';
	signal s_envelope_volume : std_logic_vector(3 downto 0) := "0000";
	signal s_envelope_q : std_logic_vector(3 downto 0);
	signal s_sweep_enable : std_logic := '0';
	signal s_sweep_period : std_logic_vector(2 downto 0) := "000";
	signal s_sweep_negate : std_logic := '0';
	signal s_sweep_shift : std_logic_vector(2 downto 0) := "000";
	signal s_sweep_update : std_logic := '0';
	signal s_length_active : std_logic;
	signal s_sweep_counter : std_logic_vector(2 downto 0) := "000";
	signal s_duty_counter : std_logic_vector(2 downto 0) := "000";
	signal s_current_period : std_logic_vector(10 downto 0) := 11x"0000";
	signal s_freq_counter : std_logic_vector(10 downto 0) := 11x"0000";
	signal s_shift_res : std_logic_vector(10 downto 0);
	signal s_target_period : std_logic_vector(11 downto 0);
	signal s_target_in_range : boolean;
	signal s_write_ch : boolean;
	signal s_write_r0 : boolean;
	signal s_write_r1 : boolean;
	signal s_write_r2 : boolean;
	signal s_write_r3 : boolean;
	signal s_duty_index : integer range 0 to 31;
	signal s_sweep_reload : boolean := false;
	signal s_timer_reload : boolean := false;
	signal s_timer_done : boolean;

begin

	ev : envelope port map
	(
		i_clk => i_clk,
		i_clk_enable => i_envelope_clk,
		i_reset_n => i_reset_n,
		i_reload => s_envelope_reload,
		i_loop => s_envelope_loop,
		i_disable => s_envelope_disable,
		i_volume => s_envelope_volume,
		o_q => s_envelope_q
	);
	
	lc : length_counter port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_lcounter_clk => i_lcounter_clk,
		i_channel_enable => i_enable,
		i_channel_reload => i_reload,
		i_enable => not s_envelope_loop,
		i_addr => i_addr,
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n,
		o_active => s_length_active
	);
	
	-- Register
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_duty <= "00";
				s_envelope_loop <= '0';
				s_envelope_disable <= '1';
				s_envelope_volume <= "0000";
			elsif i_clk_enable = '1' then
				if s_write_r0 then
					s_duty <= i_data(7 downto 6);
					s_envelope_loop <= i_data(5);
					s_envelope_disable <= i_data(4);
					s_envelope_volume <= i_data(3 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sweep_enable <= '0';
				s_sweep_period <= "000";
				s_sweep_negate <= '0';
				s_sweep_shift <= "000";
			elsif i_clk_enable = '1' then
				if s_write_r1 then
					s_sweep_enable <= i_data(7) and (i_data(2) or i_data(1) or i_data(0));
					s_sweep_period <= i_data(6 downto 4);
					s_sweep_negate <= i_data(3);
					s_sweep_shift <= i_data(2 downto 0);
				end if;
			end if;
		end if;
	end process;
		
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sweep_reload <= false;
			elsif i_clk_enable = '1' then
				if s_write_r1 then
					s_sweep_reload <= true;
				elsif i_lcounter_clk = '1' then
					s_sweep_reload <= false;
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_timer_reload <= false;
			elsif i_clk_enable = '1' then
				if s_write_r3 then
					s_timer_reload <= true;
				elsif i_apu_clk = '1' then
					s_timer_reload <= false;
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_envelope_reload <= false;
			elsif i_clk_enable = '1' then
				if s_write_r3 then
					s_envelope_reload <= true;
				elsif i_envelope_clk = '1' then
					s_envelope_reload <= false;
				end if;
			end if;
		end if;
	end process;
	
	-- Duty
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_duty_counter <= "000";
			elsif i_apu_clk = '1' then
				if s_timer_reload then
					s_duty_counter <= "000";
				elsif s_timer_done then
					s_duty_counter <= s_duty_counter - "001";
				end if;
			end if;
		end if;
	end process;
	
	-- Timer
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_freq_counter <= 11x"0000";
			elsif i_apu_clk = '1' then
				if s_timer_done or s_timer_reload then
					s_freq_counter <= s_current_period;
				else
					s_freq_counter <= s_freq_counter - 11x"0001";
				end if;
			end if;
		end if;
	end process;

	-- Sweep
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_current_period <= 11x"0000";
			elsif i_clk_enable = '1' then
				if s_write_r2 then
					s_current_period(7 downto 0) <= i_data;
				elsif s_write_r3 then
					s_current_period(10 downto 8) <= i_data(2 downto 0);
				elsif (i_lcounter_clk = '1') and (s_sweep_enable = '1') and (s_sweep_counter = "000") and s_target_in_range then
					s_current_period <= s_target_period(10 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sweep_counter <= "000";
			elsif i_lcounter_clk = '1' then
				if s_sweep_reload or (s_sweep_counter = "000") then
					s_sweep_counter <= s_sweep_period;
				else
					s_sweep_counter <= s_sweep_counter - "001";
				end if;
			end if;
		end if;
	end process;

	process (s_current_period, s_sweep_shift)
	begin
		case s_sweep_shift is
				
			when "001" =>
				s_shift_res <= '0' & s_current_period(10 downto 1);
				
			when "010" =>
				s_shift_res <= "00" & s_current_period(10 downto 2);
				
			when "011" =>
				s_shift_res <= "000" & s_current_period(10 downto 3);
				
			when "100" =>
				s_shift_res <= "0000" & s_current_period(10 downto 4);
				
			when "101" =>
				s_shift_res <= "00000" & s_current_period(10 downto 5);
				
			when "110" =>
				s_shift_res <= "000000" & s_current_period(10 downto 6);
				
			when "111" =>
				s_shift_res <= "0000000" & s_current_period(10 downto 7);

 			when others =>
				s_shift_res <= s_current_period;

		end case;
	end process;
	
	s_write_ch <= (i_cs_n = '0') and (i_write_enable = '1');
	s_write_r0 <= s_write_ch and (i_addr = "00");
	s_write_r1 <= s_write_ch and (i_addr = "01");
	s_write_r2 <= s_write_ch and (i_addr = "10");
	s_write_r3 <= s_write_ch and (i_addr = "11");
	s_timer_done <= s_freq_counter = 11x"0000";
	s_target_period <= ('0' & s_current_period) + ('0' & s_shift_res) when s_sweep_negate = '0'
	                   else ('0' & s_current_period) + ('1' & not(s_shift_res)) + (10x"0000" & INCREMENT);
	s_target_in_range <= (s_current_period(10 downto 3) /= "00000000") and ((s_target_period(11) = '0') or (s_sweep_negate = '1'));
	s_duty_index <= to_integer(unsigned(s_duty & s_duty_counter));
	
	o_q <= s_envelope_q when (DUTY_TABLE(s_duty_index) = '1') and s_target_in_range and (s_length_active = '1') and (i_enable = '1') else "0000";
	o_active <= s_length_active;

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity triangle_channel is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic;
		i_reset_n : in std_logic := '1';
		i_envelope_clk : in std_logic := '1';
		i_lcounter_clk : in std_logic := '1';
		i_addr : in std_logic_vector(1 downto 0);
		i_data : in std_logic_vector(7 downto 0);
		i_write_enable : in std_logic := '0';
		i_cs_n : in std_logic := '1';
		i_enable : in std_logic := '0';
		i_reload : in std_logic := '0';
		o_active : out std_logic;
		o_q : out std_logic_vector(3 downto 0)
	);
end triangle_channel;

architecture behavioral of triangle_channel is
	component length_counter is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n : in std_logic := '1';
			i_lcounter_clk : in std_logic := '1';
			i_channel_enable : in std_logic := '1';
			i_channel_reload : in std_logic := '0';
			i_enable : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			o_active : out std_logic
		);
	end component;

	signal s_linear_control : std_logic := '1';
	signal s_linear_load : std_logic_vector(6 downto 0) := 7x"00";
	signal s_linear_counter : std_logic_vector(6 downto 0) := 7x"00";
	signal s_linear_reload : boolean := false;
	signal s_linear_active : boolean;
	signal s_length_active : std_logic;
	signal s_timer_value : std_logic_vector(10 downto 0) := 11x"0000";
	signal s_timer_counter : std_logic_vector(10 downto 0) := 11x"0000";
	signal s_length_counter : std_logic_vector(7 downto 0) := x"00";
	signal s_sequencer : std_logic_vector(4 downto 0) := "00000";
	signal s_sequencer_res : std_logic_vector(4 downto 0);
	signal s_timer_enable : boolean;
	signal s_timer_done : boolean;
	signal s_write_ch : boolean;
	signal s_write_r0 : boolean;
	signal s_write_r2 : boolean;
	signal s_write_r3 : boolean;
begin

	lc : length_counter port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_lcounter_clk => i_lcounter_clk,
		i_channel_enable => i_enable,
		i_channel_reload => i_reload,
		i_enable => not s_linear_control,
		i_addr => i_addr,
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n,
		o_active => s_length_active
	);

	-- Register
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_linear_control <= '1';
				s_linear_load <= 7x"00";
			elsif i_clk_enable = '1' then
				if s_write_r0 then
					s_linear_control <= i_data(7);
					s_linear_load <= i_data(6 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_timer_value <= 11x"0000";
			elsif i_clk_enable = '1' then
				if s_write_r2 then
					s_timer_value(7 downto 0) <= i_data;
				elsif s_write_r3 then
					s_timer_value(10 downto 8) <= i_data(2 downto 0);
				end if;
			end if;
		end if;
	end process;
		
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_linear_reload <= false;
			elsif i_clk_enable = '1' then
				if s_write_r3 then
					s_linear_reload <= true;
				elsif (i_envelope_clk = '1') and (s_linear_control = '0') then
					s_linear_reload <= false;
				end if;
			end if;
		end if;
	end process;
	
	-- Linear Counter
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_linear_counter <= 7x"00";
			elsif i_envelope_clk = '1' then
				if s_linear_reload then
					s_linear_counter <= s_linear_load;
				elsif s_linear_active then
					s_linear_counter <= s_linear_counter - 7x"01";
				end if;
			end if;
		end if;
	end process;
	
	-- Timer
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_timer_counter <= 11x"0000";
			elsif i_clk_enable = '1' then
				if s_timer_enable then
					if s_timer_done then
						s_timer_counter <= s_timer_value;
					else
						s_timer_counter <= s_timer_counter - 11x"0001";
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sequencer <= "00000";
			elsif i_clk_enable = '1' then
				if s_timer_done and s_timer_enable then
					s_sequencer <= s_sequencer + "00001";
				end if;
			end if;
		end if;
	end process;

	s_linear_active <= (s_linear_counter /= 7x"00");
	s_timer_enable <= (s_length_active = '1') and s_linear_active;
	s_timer_done <= s_timer_counter = 11x"0000";
	s_sequencer_res <= s_sequencer xor 5x"1F";
	s_write_ch <= (i_cs_n = '0') and (i_write_enable = '1');
	s_write_r0 <= s_write_ch and (i_addr = "00");
	s_write_r2 <= s_write_ch and (i_addr = "10");
	s_write_r3 <= s_write_ch and (i_addr = "11");

	o_active <= s_length_active;
	o_q <= s_sequencer(3 downto 0) when s_sequencer(4) = '1' else s_sequencer_res(3 downto 0);

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity noise_channel is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic;
		i_reset_n : in std_logic := '1';
		i_apu_clk : in std_logic := '1';
		i_envelope_clk : in std_logic := '1';
		i_lcounter_clk : in std_logic := '1';
		i_addr : in std_logic_vector(1 downto 0);
		i_data : in std_logic_vector(7 downto 0);
		i_write_enable : in std_logic := '0';
		i_cs_n : in std_logic := '1';
		i_enable : in std_logic := '0';
		i_reload : in std_logic := '0';
		i_video_mode : in video_mode_t := ntsc;
		o_active : out std_logic;
		o_q : out std_logic_vector(3 downto 0)
	);
end noise_channel;

architecture behavioral of noise_channel is
	component envelope is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n : in std_logic := '1';
			i_reload : in boolean := false;
			i_loop : in std_logic := '0';
			i_disable : in std_logic := '1';
			i_volume : in std_logic_vector(3 downto 0) := "0000";
			o_q : out std_logic_vector(3 downto 0)
		);
	end component;
	component length_counter is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic := '1';
			i_reset_n : in std_logic := '1';
			i_lcounter_clk : in std_logic := '1';
			i_channel_enable : in std_logic := '1';
			i_channel_reload : in std_logic := '0';
			i_enable : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			o_active : out std_logic
		);
	end component;

	/*
	NTSC   4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068
	PAL    4, 8, 14, 30, 60, 88, 118, 148, 188, 236, 354, 472, 708,  944, 1890, 3778
	*/

	type period_table_t is array (0 to 15) of std_logic_vector(11 downto 0);
	constant PERIOD_TABLE_NTSC : period_table_t := ( 12x"0004", 12x"0008", 12x"0010", 12x"0020", 12x"0040", 12x"0060", 12x"0080", 12x"00A0",
												                12x"00CA", 12x"00FE", 12x"017C", 12x"01FC", 12x"02FA", 12x"03F8", 12x"07F2", 12x"0FE4" );
	constant PERIOD_TABLE_PAL : period_table_t := ( 12x"0004", 12x"0008", 12x"000E", 12x"001E", 12x"003C", 12x"0058", 12x"0076", 12x"0094",
												               12x"00BC", 12x"00EC", 12x"0162", 12x"01D8", 12x"02C4", 12x"03B0", 12x"0762", 12x"0EC2" );
																	
	signal s_envelope_reload : boolean := false;
	signal s_envelope_loop : std_logic := '0';
	signal s_envelope_disable : std_logic := '1';
	signal s_envelope_volume : std_logic_vector(3 downto 0) := "0000";
	signal s_envelope_q : std_logic_vector(3 downto 0);
	signal s_length_active : std_logic;
	signal s_shift_mode : std_logic := '0';
	signal s_shift_bit : std_logic;
	signal s_shift_new : std_logic;
	signal s_noise_shift : std_logic_vector(14 downto 0) := 15x"01";
	signal s_timer_value : std_logic_vector(11 downto 0) := 12x"0000";
	signal s_timer_counter : std_logic_vector(11 downto 0) := 12x"0000";
	signal s_timer_done : boolean;
	signal s_write_ch : boolean;
	signal s_write_r0 : boolean;
	signal s_write_r2 : boolean;
	signal s_write_r3 : boolean;
	signal s_period_table : period_table_t;
begin

	ev : envelope port map
	(
		i_clk => i_clk,
		i_clk_enable => i_envelope_clk,
		i_reset_n => i_reset_n,
		i_reload => s_envelope_reload,
		i_loop => s_envelope_loop,
		i_disable => s_envelope_disable,
		i_volume => s_envelope_volume,
		o_q => s_envelope_q
	);
	
	lc : length_counter port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_lcounter_clk => i_lcounter_clk,
		i_channel_enable => i_enable,
		i_channel_reload => i_reload,
		i_enable => not s_envelope_loop,
		i_addr => i_addr,
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n,
		o_active => s_length_active
	);
	
	-- Register
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_envelope_volume <= "0000";
				s_envelope_disable <= '1';
				s_envelope_loop <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r0 then
					s_envelope_volume <= i_data(3 downto 0);
					s_envelope_disable <= i_data(4);
					s_envelope_loop <= i_data(5);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
		variable period_index : integer range 0 to 15;
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_shift_mode <= '0';
				s_timer_value <= 12x"00";
			elsif i_clk_enable = '1' then
				if s_write_r2 then
					s_shift_mode <= i_data(7);
					period_index := to_integer(unsigned(i_data(3 downto 0)));
					s_timer_value <= s_period_table(period_index);
				end if;
			end if;
		end if;
	end process;
		
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_envelope_reload <= false;
			elsif i_clk_enable = '1' then
				if s_write_r3 then
					s_envelope_reload <= true;
				elsif i_envelope_clk = '1' then
					s_envelope_reload <= false;
				end if;
			end if;
		end if;
	end process;
	
	-- Timer

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_timer_counter <= 12x"0000";
			elsif i_apu_clk = '1' then
				if s_timer_done then
					s_timer_counter <= s_timer_value;
				else
					s_timer_counter <= s_timer_counter - 12x"0001";
				end if;
			end if;
		end if;
	end process;
	
	-- Shift

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_noise_shift <= 15x"01";
			elsif (i_apu_clk = '1') and s_timer_done then
				s_noise_shift <= s_shift_new & s_noise_shift(14 downto 1);
			end if;
		end if;
	end process;

	s_shift_bit <= s_noise_shift(6) when s_shift_mode = '1' else s_noise_shift(1);
	s_shift_new <= s_shift_bit xor s_noise_shift(0);
	s_timer_done <= s_timer_counter = 12x"0000";
	s_write_ch <= (i_cs_n = '0') and (i_write_enable = '1');
	s_write_r0 <= s_write_ch and (i_addr = "00");
	s_write_r2 <= s_write_ch and (i_addr = "10");
	s_write_r3 <= s_write_ch and (i_addr = "11");
	s_period_table <= PERIOD_TABLE_PAL when i_video_mode = pal else PERIOD_TABLE_NTSC;
	
	o_active <= s_length_active;
	o_q <= s_envelope_q when (s_noise_shift(0) = '0') and (s_length_active = '1') else "0000";

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity dmc_channel is
	port
	(
		i_clk : in std_logic;
		i_clk_enable : in std_logic;
		i_reset_n : in std_logic := '1';
		i_addr : in std_logic_vector(1 downto 0);
		i_data : in std_logic_vector(7 downto 0);
		i_dma_busy : in std_logic := '0';
		i_dma_data : in std_logic_vector(7 downto 0) := x"00";
		i_write_enable : in std_logic := '0';
		i_cs_n : in std_logic := '1';
		i_enable : in std_logic := '0';
		i_reload : in std_logic := '0';
		i_video_mode : in video_mode_t := ntsc;
		o_dma_request : out std_logic;
		o_dma_addr : out std_logic_vector(15 downto 0);
		o_active : out std_logic;
		o_int_pending : out std_logic;
		o_q : out std_logic_vector(6 downto 0)
	);
end dmc_channel;

architecture behavioral of dmc_channel is
	type period_t is array (0 to 15) of std_logic_vector(8 downto 0);
	constant PERIOD_TABLE_NTSC : period_t := ( 9x"1AB", 9x"17B", 9x"153", 9x"13F", 9x"11D", 9x"0FD", 9x"0E1", 9x"0D5",
	                                           9x"0BD", 9x"09F", 9x"08D", 9x"07F", 9x"069", 9x"053", 9x"047", 9x"035" );
	constant PERIOD_TABLE_PAL : period_t := ( 9x"18E", 9x"162", 9x"13C", 9x"12A", 9x"114", 9x"0EC", 9x"0D2", 9x"0C6",
	                                          9x"0B0", 9x"094", 9x"084", 9x"076", 9x"062", 9x"04E", 9x"042", 9x"032" );
	
	signal s_int_enable : std_logic := '0';
	signal s_loop : std_logic := '0';
	signal s_timer_counter : std_logic_vector(8 downto 0) := 9x"000";
	signal s_timer_value : std_logic_vector(8 downto 0) := 9x"000";
	signal s_length_load : unsigned(11 downto 0) := 12x"000";
	signal s_addr_load : std_logic_vector(15 downto 0) := x"0000";
	signal s_output : std_logic_vector(6 downto 0) := 7x"00";
	signal s_next_output : std_logic_vector(7 downto 0);
	signal s_write_ch : boolean;
	signal s_write_r0 : boolean;
	signal s_write_r1 : boolean;
	signal s_write_r2 : boolean;
	signal s_write_r3 : boolean;
	signal s_timer_done : boolean;
	signal s_silent : boolean := true;
	signal s_bits_remaining : unsigned(2 downto 0) := "000";
	signal s_shift_buffer : std_logic_vector(7 downto 0) := x"00";
	signal s_sample_buffer_empty : boolean := true;
	signal s_bits_empty : boolean;
	signal s_dma_request : std_logic := '0';
	signal s_dma_addr : std_logic_vector(15 downto 0) := x"0000";
	signal s_next_addr : std_logic_vector(15 downto 0) := x"0000";
	signal s_length : unsigned(11 downto 0) := 12x"000";
	signal s_dma_busy_d : std_logic := '0';
	signal s_int_pending : std_logic := '0';
	signal s_int_trigger : boolean := false;
	signal s_dma_free : boolean;
	signal s_dma_done : boolean;
	signal s_period_table : period_t;
	
begin

	-- DMC
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_loop <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r0 then
					s_loop <= i_data(6);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
		variable period_index : integer range 0 to 15;
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_timer_value <= 9x"000";
			elsif i_clk_enable = '1' then
				if s_write_r0 then
					period_index := to_integer(unsigned(i_data(3 downto 0)));
					s_timer_value <= s_period_table(period_index);
				end if;
			end if;
		end if;
	end process;
	
	-- Output
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_output <= 7x"00";
			elsif i_clk_enable = '1' then
				if s_write_r1 then
					s_output <= i_data(6 downto 0);
				elsif s_timer_done and not s_silent then
					if s_next_output(7) = '0' then
						s_output <= s_next_output(6 downto 0);
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- Addr
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_addr_load <= x"0000";
			elsif i_clk_enable = '1' then
				if s_write_r2 then
					s_addr_load <= x"C000" or ("00" & i_data & "000000");
				end if;
			end if;
		end if;
	end process;
	
	-- Length Counter
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_length_load <= 12x"000";
			elsif i_clk_enable = '1' then
				if s_write_r3 then
					s_length_load <= unsigned(i_data) & "0001";
				end if;
			end if;
		end if;
	end process;
	
	-- Timer
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_timer_counter <= 9x"000";
			elsif i_clk_enable = '1' then
				if s_timer_done then
					s_timer_counter <= s_timer_value;
				else
					s_timer_counter <= s_timer_counter - 9x"001";
				end if;
			end if;
		end if;
	end process;
	
	s_timer_done <= s_timer_counter = "000";
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_bits_remaining <= "000";
				s_shift_buffer <= x"00";
				s_silent <= true;
			elsif (i_clk_enable = '1') and s_timer_done then
				s_bits_remaining <= s_bits_remaining - "001";
				s_shift_buffer <= '0' & s_shift_buffer(7 downto 1);
						
				if s_bits_empty then
					s_shift_buffer <= i_dma_data;
					s_silent <= s_sample_buffer_empty;
				end if;
			end if;
		end if;
	end process;
	
	s_bits_empty <= s_bits_remaining = "000";
	
	-- DMA Response & Sample Buffer
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sample_buffer_empty <= true;
				s_dma_busy_d <= '0';
			elsif i_clk_enable = '1' then
				s_dma_busy_d <= i_dma_busy;
				
				if s_dma_done then
					s_sample_buffer_empty <= false;
				elsif s_timer_done and s_bits_empty then
					s_sample_buffer_empty <= true;
				end if;
			end if;
		end if;
	end process;
	
	-- DMA Request
	
	process (i_clk)
		variable remaining_length : unsigned(11 downto 0);
		variable sample_addr : std_logic_vector(15 downto 0);
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_dma_request <= '0';
				s_int_trigger <= false;
			elsif i_clk_enable = '1' then
				s_dma_request <= '0';
				remaining_length := s_length;
				sample_addr := s_next_addr;
				s_int_trigger <= false;
				
				if i_reload = '1' then
					if i_enable = '0' then
						remaining_length := 12x"000";
					elsif s_length = 12x"000" then
						remaining_length := s_length_load;
						sample_addr := s_addr_load;
					end if;
				end if;	

				if s_sample_buffer_empty and s_dma_free and not s_dma_done and (remaining_length /= 12x"000") then
					s_dma_request <= '1';
					s_dma_addr <= sample_addr;
				
					if remaining_length = 12x"001" then
						-- if last byte is requested
						if s_loop = '1' then
							-- restart playback
							remaining_length := s_length_load;
							sample_addr := s_addr_load;
						else
							-- stop playback
							remaining_length := 12x"000";
							s_int_trigger <= true;
						end if;
					else
						-- determine address of next byte
						sample_addr := (sample_addr + x"0001") or x"8000";
						remaining_length := remaining_length - 12x"001";
					end if;
				end if;
				
				s_next_addr <= sample_addr;
				s_length <= remaining_length;
			end if;
		end if;
	end process;
	
	o_dma_request <= s_dma_request;
	o_dma_addr <= s_dma_addr;
	
	-- Interrupt
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_int_enable <= '0';
			elsif (i_clk_enable = '1') and s_write_r0 then
				s_int_enable <= i_data(7);
			end if;
		end if;
	end process;

	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_int_pending <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r0 and (i_data(7) = '0') then
					s_int_pending <= '0';
				elsif s_int_trigger and (s_int_enable = '1') then
					s_int_pending <= '1';
				elsif i_reload = '1' then
					s_int_pending <= '0';
				end if;
			end if;
		end if;
	end process;
	
	o_int_pending <= s_int_pending;
	
	-- Misc

	s_write_ch <= (i_cs_n = '0') and (i_write_enable = '1');
	s_write_r0 <= s_write_ch and (i_addr = "00");
	s_write_r1 <= s_write_ch and (i_addr = "01");
	s_write_r2 <= s_write_ch and (i_addr = "10");
	s_write_r3 <= s_write_ch and (i_addr = "11");
	s_next_output <= ('0' & s_output) + x"02" when s_shift_buffer(0) = '1' else ('0' & s_output - x"02");
	s_dma_free <= (s_dma_request = '0') and (i_dma_busy = '0');
	s_dma_done <= (s_dma_busy_d = '1') and (i_dma_busy = '0');
	s_period_table <= PERIOD_TABLE_PAL when i_video_mode = pal else PERIOD_TABLE_NTSC;
	
	o_active <= '0' when s_length = 12x"000" else '1';
	o_q <= s_output;

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity dma is
	generic
	(
		TARGET_ADDR : std_logic_vector(15 downto 0) := x"2004"
	);
	port
	(
		i_clk : in std_logic;
		i_reset_n : in std_logic := '1';
		i_clk_enable : in std_logic := '1';
		i_write_enable : in std_logic := '0';
		i_seq_enable : in std_logic := '0';
		i_seq_addr : in std_logic_vector(7 downto 0) := x"02";
		i_single_enable : in std_logic := '0';
		i_single_addr : in std_logic_vector(15 downto 0) := x"c045";
		i_data : in std_logic_vector(7 downto 0) := x"00";
		o_single_busy : out std_logic;
		o_single_q : out std_logic_vector(7 downto 0);
		o_addr : out std_logic_vector(15 downto 0);
		o_data : out std_logic_vector(7 downto 0);
		o_write_enable : out std_logic;
		o_ready : out std_logic;
		o_active : out std_logic
	);
end dma;

architecture behavioral of dma is

	type seq_mode_t is (idle, wait_read, align, transfer);
	type sin_mode_t is (idle, wait_read, wait_byte, align, read_byte);
	
	signal s_seq_mode : seq_mode_t := idle;
	signal s_sin_mode : sin_mode_t := idle;
	signal s_addr : std_logic_vector(7 downto 0) := x"00";
	signal s_data : std_logic_vector(7 downto 0) := x"00";
	signal s_write_enable : std_logic := '0';
	signal s_single_q : std_logic_vector(7 downto 0) := x"00";
	signal s_single_non_busy : boolean;
	signal s_fetch_single : boolean := false;

begin

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_write_enable <= '0';
			elsif i_clk_enable = '1' then
				s_write_enable <= not s_write_enable;
			end if;
		end if;
	end process;
	
	-- Single DMA (DMC)
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_single_q <= x"00";
			elsif (i_clk_enable = '1') and s_fetch_single then
				s_single_q <= i_data;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sin_mode <= idle;
				s_fetch_single <= false;
			elsif i_clk_enable = '1' then
				s_fetch_single <= false;
			
				case s_sin_mode is
					
					when idle =>
						if i_single_enable = '1' then
							s_sin_mode <= wait_read;
						end if;
						
					when wait_read =>
						if i_write_enable = '0' then
							s_sin_mode <= wait_byte;
						end if;
						
					when wait_byte =>
						if s_write_enable = '0' then
							s_sin_mode <= align;
						else
							s_sin_mode <= read_byte;
						end if;
						
					when align =>
						s_sin_mode <= read_byte;
						
					when read_byte =>
						s_sin_mode <= idle;
						s_fetch_single <= true;

				end case;
			end if;
		end if;
	end process;
	
	-- Sequencial DMA (OAM)

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_seq_mode <= idle;
			elsif i_clk_enable = '1' then
				case s_seq_mode is
					
					when idle =>
						if i_seq_enable = '1' then
							s_addr <= x"00";
							s_seq_mode <= wait_read;
						end if;
						
					when wait_read =>
						if i_write_enable = '0' then
							if s_write_enable = '0' then
								s_seq_mode <= align;
							else
								s_seq_mode <= transfer;
							end if;
						end if;
						
					when align =>
						s_seq_mode <= transfer;
						
					when transfer =>
						if s_write_enable = '1' then
							if s_addr = x"ff" then
								s_seq_mode <= idle;
							elsif not s_fetch_single then
								s_addr <= s_addr + x"01";
							end if;
						end if;

				end case;
			end if;
		end if;
	end process;
	
	o_addr <= i_single_addr when s_sin_mode = read_byte
	          else i_seq_addr & s_addr when s_write_enable = '0'
				 else TARGET_ADDR;
	o_ready <= '1' when (s_seq_mode = idle) and (s_sin_mode = idle) else i_write_enable;
	o_active <= '0' when s_fetch_single
               else '1' when (s_seq_mode = transfer) or (s_sin_mode = read_byte)
					else '0';
	o_data <= i_data;
	o_write_enable <= s_write_enable;
	o_single_busy <= '1' when s_fetch_single or (s_sin_mode /= idle) else '0';
	o_single_q <= s_single_q;

end behavioral;

/********************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity apu is
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
end apu;

architecture behavioral of apu is
	component square_channel is
		generic
		(
			INCREMENT : std_logic := '0'
		);
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic;
			i_reset_n : in std_logic := '1';
			i_apu_clk : in std_logic;
			i_envelope_clk : in std_logic := '1';
			i_lcounter_clk : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			i_enable : in std_logic := '0';
			i_reload : in std_logic := '0';
			o_active : out std_logic;
			o_q : out std_logic_vector(3 downto 0)
		);
	end component;
	component triangle_channel is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic;
			i_reset_n : in std_logic := '1';
			i_envelope_clk : in std_logic := '1';
			i_lcounter_clk : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			i_enable : in std_logic := '0';
			i_reload : in std_logic := '0';
			o_active : out std_logic;
			o_q : out std_logic_vector(3 downto 0)
		);
	end component;
	component noise_channel is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic;
			i_reset_n : in std_logic := '1';
			i_apu_clk : in std_logic := '1';
			i_envelope_clk : in std_logic := '1';
			i_lcounter_clk : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			i_enable : in std_logic := '0';
			i_reload : in std_logic := '0';
			i_video_mode : in video_mode_t := ntsc;
			o_active : out std_logic;
			o_q : out std_logic_vector(3 downto 0)
		);
	end component;
	component dmc_channel is
		port
		(
			i_clk : in std_logic;
			i_clk_enable : in std_logic;
			i_reset_n : in std_logic := '1';
			i_addr : in std_logic_vector(1 downto 0);
			i_data : in std_logic_vector(7 downto 0);
			i_dma_busy : in std_logic := '0';
			i_dma_data : in std_logic_vector(7 downto 0) := x"00";
			i_write_enable : in std_logic := '0';
			i_cs_n : in std_logic := '1';
			i_enable : in std_logic := '0';
			i_reload : in std_logic := '0';
			i_video_mode : in video_mode_t := ntsc;
			o_dma_request : out std_logic;
			o_dma_addr : out std_logic_vector(15 downto 0);
			o_active : out std_logic;
			o_int_pending : out std_logic;
			o_q : out std_logic_vector(6 downto 0)
		);
	end component;
	component dma is
		generic
		(
			TARGET_ADDR : std_logic_vector(15 downto 0) := x"2004"
		);
		port
		(
			i_clk : in std_logic;
			i_reset_n : in std_logic := '1';
			i_clk_enable : in std_logic := '1';
			i_write_enable : in std_logic := '0';
			i_seq_enable : in std_logic := '0';
			i_seq_addr : in std_logic_vector(7 downto 0) := x"02";
			i_single_enable : in std_logic := '0';
			i_single_addr : in std_logic_vector(15 downto 0) := x"c045";
			i_data : in std_logic_vector(7 downto 0) := x"00";
			o_single_busy : out std_logic;
			o_single_q : out std_logic_vector(7 downto 0);
			o_addr : out std_logic_vector(15 downto 0);
			o_data : out std_logic_vector(7 downto 0);
			o_write_enable : out std_logic;
			o_ready : out std_logic;
			o_active : out std_logic
		);
	end component;
	
	type square_table_t is array (0 to 30) of std_logic_vector(15 downto 0);
	type tnd_table_t is array (0 to 202) of std_logic_vector(15 downto 0);
	
	-- this values were calculated by the equations in http://wiki.nesdev.com/w/index.php/APU_Mixer
	
	/*
	Base 0xFFFF
	
	constant SQUARE_LOOKUP : square_table_t := (	x"0000", x"02f9", x"05df", x"08b4", x"0b78", x"0e2c", x"10cf", x"1364", x"15e9",
	                                             x"1860", x"1aca", x"1d26", x"1f75", x"21b8", x"23ee", x"2619", x"2838", x"2a4c",
																x"2c56", x"2e55", x"304a", x"3235", x"3416", x"35ef", x"37be", x"3985", x"3b43",
																x"3cf9", x"3ea7", x"404d", x"41ec" );
																
	constant TND_LOOKUP : tnd_table_t := ( x"0000", x"01b7", x"036b", x"051b", x"06c7", x"0870", x"0a16", x"0bb8", x"0d57", x"0ef2",
	                                       x"108b", x"1220", x"13b2", x"1541", x"16cc", x"1855", x"19db", x"1b5d", x"1cdd", x"1e5a",
														x"1fd4", x"214b", x"22bf", x"2430", x"259f", x"270b", x"2874", x"29db", x"2b3e", x"2ca0",
														x"2dfe", x"2f5b", x"30b4", x"320b", x"3360", x"34b2", x"3602", x"374f", x"389a", x"39e3",
														x"3b29", x"3c6d", x"3daf", x"3eee", x"402c", x"4167", x"42a0", x"43d6", x"450b", x"463d",
														x"476e", x"489c", x"49c8", x"4af3", x"4c1b", x"4d41", x"4e66", x"4f88", x"50a8", x"51c7",
														x"52e4", x"53fe", x"5517", x"562e", x"5744", x"5857", x"5969", x"5a79", x"5b87", x"5c93",
														x"5d9e", x"5ea7", x"5fae", x"60b4", x"61b8", x"62ba", x"63bb", x"64ba", x"65b8", x"66b4",
														x"67ae", x"68a7", x"699f", x"6a95", x"6b89", x"6c7c", x"6d6d", x"6e5d", x"6f4c", x"7039",
														x"7124", x"720e", x"72f7", x"73df", x"74c5", x"75aa", x"768d", x"776f", x"7850", x"792f",
														x"7a0d", x"7aea", x"7bc5", x"7ca0", x"7d79", x"7e50", x"7f27", x"7ffc", x"80d0", x"81a3",
														x"8275", x"8345", x"8415", x"84e3", x"85b0", x"867c", x"8746", x"8810", x"88d8", x"89a0",
														x"8a66", x"8b2b", x"8bef", x"8cb2", x"8d74", x"8e35", x"8ef5", x"8fb4", x"9072", x"912e",
														x"91ea", x"92a5", x"935f", x"9418", x"94cf", x"9586", x"963c", x"96f1", x"97a5", x"9858",
														x"990a", x"99bb", x"9a6b", x"9b1b", x"9bc9", x"9c77", x"9d23", x"9dcf", x"9e7a", x"9f24",
														x"9fcd", x"a075", x"a11d", x"a1c3", x"a269", x"a30e", x"a3b2", x"a455", x"a4f8", x"a59a",
														x"a63a", x"a6da", x"a77a", x"a818", x"a8b6", x"a953", x"a9ef", x"aa8a", x"ab25", x"abbf",
														x"ac58", x"acf0", x"ad88", x"ae1f", x"aeb5", x"af4b", x"afe0", x"b074", x"b107", x"b19a",
														x"b22c", x"b2bd", x"b34e", x"b3de", x"b46d", x"b4fb", x"b589", x"b617", x"b6a3", x"b72f",
														x"b7bb", x"b845", x"b8cf", x"b959", x"b9e1", x"ba6a", x"baf1", x"bb78", x"bbfe", x"bc84",
														x"bd09", x"bd8e", x"be12" );
														
	*/

	constant SQUARE_LOOKUP : square_table_t := (	x"0000", x"011d", x"0234", x"0344", x"044d", x"0550", x"064e", x"0745", x"0837",
	                                             x"0924", x"0a0c", x"0aee", x"0bcc", x"0ca5", x"0d79", x"0e49", x"0f15", x"0fdd",
																x"10a0", x"1160", x"121c", x"12d4", x"1388", x"143a", x"14e7", x"1592", x"1639",
																x"16de", x"177f", x"181d", x"18b9" );
																
	constant TND_LOOKUP : tnd_table_t := ( x"0000", x"00a5", x"0148", x"01ea", x"028b", x"032a", x"03c8", x"0465", x"0501", x"059b",
	                                       x"0634", x"06cc", x"0763", x"07f8", x"088d", x"0920", x"09b2", x"0a43", x"0ad3", x"0b62",
														x"0bef", x"0c7c", x"0d08", x"0d92", x"0e1c", x"0ea4", x"0f2c", x"0fb2", x"1037", x"10bc",
														x"113f", x"11c2", x"1244", x"12c4", x"1344", x"13c3", x"1441", x"14be", x"153a", x"15b5",
														x"162f", x"16a9", x"1722", x"1799", x"1810", x"1887", x"18fc", x"1970", x"19e4", x"1a57",
														x"1ac9", x"1b3b", x"1bab", x"1c1b", x"1c8a", x"1cf9", x"1d66", x"1dd3", x"1e3f", x"1eab",
														x"1f15", x"1f7f", x"1fe9", x"2051", x"20b9", x"2121", x"2187", x"21ed", x"2253", x"22b7",
														x"231b", x"237f", x"23e1", x"2444", x"24a5", x"2506", x"2566", x"25c6", x"2625", x"2684",
														x"26e2", x"273f", x"279c", x"27f8", x"2853", x"28af", x"2909", x"2963", x"29bd", x"2a15",
														x"2a6e", x"2ac6", x"2b1d", x"2b74", x"2bca", x"2c20", x"2c75", x"2cca", x"2d1e", x"2d72",
														x"2dc5", x"2e18", x"2e6a", x"2ebc", x"2f0d", x"2f5e", x"2faf", x"2fff", x"304e", x"309d",
														x"30ec", x"313a", x"3188", x"31d5", x"3222", x"326f", x"32bb", x"3306", x"3351", x"339c",
														x"33e6", x"3430", x"347a", x"34c3", x"350c", x"3554", x"359c", x"35e4", x"362b", x"3672",
														x"36b8", x"36fe", x"3744", x"3789", x"37ce", x"3813", x"3857", x"389b", x"38de", x"3921",
														x"3964", x"39a6", x"39e9", x"3a2a", x"3a6c", x"3aad", x"3aee", x"3b2e", x"3b6e", x"3bae",
														x"3bed", x"3c2c", x"3c6b", x"3caa", x"3ce8", x"3d26", x"3d63", x"3da0", x"3ddd", x"3e1a",
														x"3e56", x"3e92", x"3ece", x"3f09", x"3f44", x"3f7f", x"3fba", x"3ff4", x"402e", x"4068",
														x"40a1", x"40da", x"4113", x"414c", x"4184", x"41bc", x"41f4", x"422c", x"4263", x"429a",
														x"42d1", x"4307", x"433d", x"4373", x"43a9", x"43df", x"4414", x"4449", x"447e", x"44b2",
														x"44e6", x"451a", x"454e", x"4582", x"45b5", x"45e8", x"461b", x"464d", x"4680", x"46b2",
														x"46e4", x"4715", x"4747" );
														
	constant REG_4014 : std_logic_vector(4 downto 0) := "10100";
	constant REG_4015 : std_logic_vector(4 downto 0) := "10101";
	constant REG_4016 : std_logic_vector(4 downto 0) := "10110";
	constant REG_4017 : std_logic_vector(4 downto 0) := "10111";
	constant REBOOT_CLK : natural := 12; -- @todo correct reset behavior, not working, value should be between 12 and 13 for (blargg 09.reset_timing)
														
	signal s_clk_divider : natural range 0 to 37281 := REBOOT_CLK;
	signal s_apu_clk : std_logic;
	signal s_envelope_clk : std_logic;
	signal s_lcounter_clk : std_logic;
	signal s_envelope_signal : std_logic;
	signal s_lcounter_signal : std_logic;
	signal s_apu_signal : std_logic := '1';
	signal s_mode : std_logic := '0';
	signal s_int_disable : std_logic := '0';
	signal s_read_apu : boolean;
	signal s_read_r15 : boolean;
	signal s_read_r16 : boolean;
	signal s_read_r17 : boolean;
	signal s_write_r14 : std_logic;
	signal s_write_r15 : boolean;
	signal s_write_r16 : boolean;
	signal s_write_r17 : boolean;
	signal s_write_apu : boolean;
	signal s_square1_q : std_logic_vector(3 downto 0) := "0000";
	signal s_square2_q : std_logic_vector(3 downto 0) := "0000";
	signal s_square_sum : std_logic_vector(4 downto 0);
	signal s_square_index : integer range 0 to 30;
	signal s_tnd_sum : std_logic_vector(7 downto 0);
	signal s_tnd_index : integer range 0 to 202;
	signal s_frame_int_pending : std_logic := '0';
	signal s_square1_enable : std_logic := '0';
	signal s_square2_enable : std_logic := '0';
	signal s_triangle_enable : std_logic := '0';
	signal s_noise_enable : std_logic := '0';
	signal s_dmc_enable : std_logic := '0';
	signal s_square1_active : std_logic := '0';
	signal s_square2_active : std_logic := '0';
	signal s_triangle_active : std_logic := '0';
	signal s_noise_active : std_logic := '0';
	signal s_dmc_active : std_logic := '0';
	signal s_triangle_q : std_logic_vector(3 downto 0) := "0000";
	signal s_noise_q : std_logic_vector(3 downto 0) := "0000";
	signal s_dmc_q : std_logic_vector(6 downto 0) := 7x"00";
	signal s_reload : std_logic := '0';
	signal s_ctrl_strobe : std_logic := '0';
	signal s_ctrl_a_clk : std_logic := '1';
	signal s_ctrl_b_clk : std_logic := '1';
	signal s_q : std_logic_vector(7 downto 0) := x"00";
	signal s_oma_addr : std_logic_vector(7 downto 0) := x"00";
	signal s_dmc_busy : std_logic;
	signal s_dmc_data : std_logic_vector(7 downto 0);
	signal s_dmc_request : std_logic;
	signal s_dmc_addr : std_logic_vector(15 downto 0);
	signal s_dmc_int_pending : std_logic;
	signal s_clock_trigger : std_logic := '0';
	signal s_frame_int_trigger : std_logic;
	signal s_frame_int_active : std_logic;
	signal s_frame_int_buffer : std_logic_vector(2 downto 0) := (others => '0');
	signal s_frame_int_visible : std_logic;
	signal s_last_cycle : std_logic;
	signal s_data : std_logic_vector(7 downto 0) := x"00";
	signal s_data_sync : std_logic_vector(7 downto 0);
	signal s_r17_written : boolean := false;
	signal s_write_r17_sync : boolean;

begin

	sq1 : square_channel generic map ( INCREMENT => '0' ) port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_apu_clk => s_apu_clk,
		i_envelope_clk => s_envelope_clk,
		i_lcounter_clk => s_lcounter_clk,
		i_addr => i_addr(1 downto 0),
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n or i_addr(4) or i_addr(3) or i_addr(2),
		i_enable => s_square1_enable,
		i_reload => s_reload,
		o_active => s_square1_active,
		o_q => s_square1_q
	);
	
	sq2 : square_channel generic map ( INCREMENT => '1' ) port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_apu_clk => s_apu_clk,
		i_envelope_clk => s_envelope_clk,
		i_lcounter_clk => s_lcounter_clk,
		i_addr => i_addr(1 downto 0),
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n or i_addr(4) or i_addr(3) or not i_addr(2),
		i_enable => s_square2_enable,
		i_reload => s_reload,
		o_active => s_square2_active,
		o_q => s_square2_q
	);

	tr : triangle_channel port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_envelope_clk => s_envelope_clk,
		i_lcounter_clk => s_lcounter_clk,
		i_addr => i_addr(1 downto 0),
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n or i_addr(4) or not i_addr(3) or i_addr(2),
		i_enable => s_triangle_enable,
		i_reload => s_reload,
		o_active => s_triangle_active,
		o_q => s_triangle_q
	);

	ns : noise_channel port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_apu_clk => s_apu_clk,
		i_envelope_clk => s_envelope_clk,
		i_lcounter_clk => s_lcounter_clk,
		i_addr => i_addr(1 downto 0),
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_cs_n => i_cs_n or i_addr(4) or not i_addr(3) or not i_addr(2),
		i_enable => s_noise_enable,
		i_reload => s_reload,
		i_video_mode => i_video_mode,
		o_active => s_noise_active,
		o_q => s_noise_q
	);
	
	dmc : dmc_channel port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_addr => i_addr(1 downto 0),
		i_data => i_data,
		i_write_enable => i_write_enable,
		i_dma_busy => s_dmc_busy,
		i_dma_data => s_dmc_data,
		i_cs_n => i_cs_n or not i_addr(4) or i_addr(3) or i_addr(2),
		i_enable => s_dmc_enable,
		i_reload => s_reload,
		i_video_mode => i_video_mode,
		o_dma_request => s_dmc_request,
		o_dma_addr => s_dmc_addr,
		o_active => s_dmc_active,
		o_int_pending => s_dmc_int_pending,
		o_q => s_dmc_q
	);
	
	dma_cmp : dma port map
	(
		i_clk => i_clk,
		i_clk_enable => i_clk_enable,
		i_reset_n => i_reset_n,
		i_write_enable => i_dma_write_enable,
		i_seq_enable => s_write_r14,
		i_seq_addr => s_oma_addr,
		i_single_enable => s_dmc_request,
		i_single_addr => s_dmc_addr,
		i_data => i_dma_q,
		o_single_busy => s_dmc_busy,
		o_single_q => s_dmc_data,
		o_addr => o_dma_addr,
		o_data => o_dma_data,
		o_write_enable => o_dma_write_enable,
		o_ready => o_dma_ready,
		o_active => o_dma_active
	);
	
	-- Mixer
	
	s_square_sum <= ('0' & s_square1_q) + ('0' & s_square2_q);
	s_square_index <= to_integer(unsigned(s_square_sum));
	s_tnd_sum <= s_triangle_q * x"3" + ("000" & s_noise_q & '0') + ('0' & s_dmc_q);
	s_tnd_index <= to_integer(unsigned(s_tnd_sum));
	o_audio <= SQUARE_LOOKUP(s_square_index) + TND_LOOKUP(s_tnd_index);
	
	-- Interrupt Disable

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_int_disable <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r17_sync then
					s_int_disable <= s_data_sync(6);
				end if;
			end if;
		end if;
	end process;
	
	-- IRQ
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_frame_int_pending <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r17_sync and (s_data_sync(6) = '1') then
					s_frame_int_pending <= '0';
				elsif s_read_r15 then
					s_frame_int_pending <= '0';
				elsif s_frame_int_trigger then
					s_frame_int_pending <= '1';
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_frame_int_buffer <= (others => '0');
			elsif i_clk_enable = '1' then
				s_frame_int_buffer <= s_frame_int_buffer(1 downto 0) & s_frame_int_active;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_frame_int_visible <= '0';
			elsif i_clk_enable = '1' then
				s_frame_int_visible <= s_frame_int_trigger or s_frame_int_pending;
			end if;
		end if;
	end process;
	
	o_int_n <= s_frame_int_pending nor s_dmc_int_pending;
	s_frame_int_active <= s_last_cycle and not s_int_disable and not s_mode;
	s_frame_int_trigger <= s_frame_int_active or s_frame_int_buffer(2);
	s_last_cycle <= '1' when (s_clk_divider = 29829) else '0';
	
	-- Frame Sequencer

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_mode <= '0';
				s_clock_trigger <= '0';
			elsif i_clk_enable = '1' then
				s_clock_trigger <= '0';
			
				if s_write_r17_sync then
					s_mode <= s_data_sync(7);
					s_clock_trigger <= s_data_sync(7);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_clk_divider <= REBOOT_CLK;
			elsif i_clk_enable = '1' then
				if s_write_r17_sync or ((s_mode = '0') and (s_clk_divider = 29829)) or ((s_mode = '1') and (s_clk_divider = 37281)) then
					s_clk_divider <= 0;
				else
					s_clk_divider <= s_clk_divider + 1;
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_envelope_signal <= '0';
				s_lcounter_signal <= '0';
				s_apu_signal <= '1';
			elsif i_clk_enable = '1' then
				s_apu_signal <= not s_apu_signal;
			
				if s_clock_trigger = '1' then
					s_envelope_signal <= '1';
					s_lcounter_signal <= '1';
				else
					case s_clk_divider is

						when 7457 =>
							s_envelope_signal <= '1';
							s_lcounter_signal <= '0';
							
						when 14913 =>
							s_envelope_signal <= '1';
							s_lcounter_signal <= '1';
							
						when 22371 =>
							s_envelope_signal <= '1';
							s_lcounter_signal <= '0';
							
						when 29829 =>
							s_envelope_signal <= not s_mode;
							s_lcounter_signal <= not s_mode;
							
						when 37281 =>
							s_envelope_signal <= '1';
							s_lcounter_signal <= '1';

						when others =>
							s_envelope_signal <= '0';
							s_lcounter_signal <= '0';
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	s_apu_clk <= s_apu_signal and i_clk_enable;
	s_envelope_clk <= s_envelope_signal and i_clk_enable;
	s_lcounter_clk <= s_lcounter_signal and i_clk_enable;
	
	-- APU Controlling
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_square1_enable <= '0';
				s_square2_enable <= '0';
				s_triangle_enable <= '0';
				s_noise_enable <= '0';
				s_dmc_enable <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r15 then
					s_square1_enable <= i_data(0);
					s_square2_enable <= i_data(1);
					s_triangle_enable <= i_data(2);
					s_noise_enable <= i_data(3);
					s_dmc_enable <= i_data(4);
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_reload <= '0';
			elsif i_clk_enable = '1' then
				if s_write_r15 then
					s_reload <= '1';
				else
					s_reload <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-- OMA-DMA
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_oma_addr <= x"00";
			elsif (i_clk_enable = '1') and (s_write_r14 = '1') then
				s_oma_addr <= i_data;
			end if;
		end if;
	end process;
	
	-- Read Port

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_q <= x"00";
			elsif (i_clk_enable = '1') and s_read_apu then
				case i_addr is
				
					when REG_4015 =>
						s_q <= s_dmc_int_pending & s_frame_int_visible & '0' & s_dmc_active & s_noise_active & s_triangle_active & s_square2_active & s_square1_active;
						
					when REG_4016 =>
						s_q <= "0000000" & not i_ctrl_a_data;
					
					when REG_4017 =>
						s_q <= "0000000" & not i_ctrl_b_data;
						
					when others =>
						s_q <= x"00";
				
				end case;
			end if;
		end if;
	end process;
	
	o_q <= s_q;
	
	-- Write Port
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_data <= x"00";
				s_r17_written <= false;
			elsif i_clk_enable = '1' then
				s_r17_written <= s_write_r17;
			
				if s_write_apu then
					s_data <= i_data;
				end if;
			end if;
		end if;
	end process;
	
	s_write_apu <= (i_cs_n = '0') and (i_write_enable = '1');
	s_write_r14 <= '1' when s_write_apu and (i_addr = REG_4014) else '0';
	s_write_r15 <= s_write_apu and (i_addr = REG_4015);
	s_write_r16 <= s_write_apu and (i_addr = REG_4016);
	s_write_r17 <= s_write_apu and (i_addr = REG_4017);
	s_write_r17_sync <= false when s_apu_signal = '0' else s_r17_written or s_write_r17;
	s_data_sync <= i_data when s_write_apu else s_data;
	
	-- Read Controller A
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_ctrl_a_clk <= '1';
			elsif i_clk_enable = '1' then
				s_ctrl_a_clk <= '1';
			
				if s_read_r16 then
					s_ctrl_a_clk <= '0';
				end if;
			end if;
		end if;
	end process;
	
	o_ctrl_a_clk <= s_ctrl_a_clk;

	-- Read Controller B
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_ctrl_b_clk <= '1';
			elsif i_clk_enable = '1' then
				s_ctrl_b_clk <= '1';
			
				if s_read_r17 then
					s_ctrl_b_clk <= '0';
				end if;
			end if;
		end if;
	end process;
	
	o_ctrl_b_clk <= s_ctrl_b_clk;
	
	-- Write Controller Strobe
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_ctrl_strobe <= '0';
			elsif (i_clk_enable = '1') and s_write_r16 then
				s_ctrl_strobe <= i_data(0);
			end if;
		end if;
	end process;
	
	o_ctrl_strobe <= s_ctrl_strobe;
	
	-- Misc

	s_read_apu <= (i_cs_n = '0') and (i_write_enable = '0');
	s_read_r15 <= s_read_apu and (i_addr = REG_4015);
	s_read_r16 <= s_read_apu and (i_addr = REG_4016);
	s_read_r17 <= s_read_apu and (i_addr = REG_4017);

end behavioral;