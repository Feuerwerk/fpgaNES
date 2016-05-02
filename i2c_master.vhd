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

entity i2c_master is
	generic
	(
		CLK_SPEED : integer := 50_000_000;
		WAIT_TIMEOUT : integer := 100
	);
	port
	(
		i_clk : in std_logic;
		i_reset_n : in std_logic := '1';
		i_enable : in std_logic := '0';
		i_active : in std_logic := '0';
		i_addr : in std_logic_vector(7 downto 0) := x"00";
		i_cmd : in std_logic_vector(7 downto 0) := x"00";
		i_data : in std_logic_vector(7 downto 0) := x"00";
		i_read_not_write : std_logic := '1';
		io_sda : inout std_logic;
		io_scl : inout std_logic;
		o_q : out std_logic_vector(7 downto 0);
		o_busy : out std_logic;
		o_ack_error : out std_logic
	);
end i2c_master;

architecture behavioral of i2c_master is
	component i2c is
		generic
		(
			input_clk : integer := 50_000_000;
			bus_clk : integer := 400_000
		);
		port
		(
			i_clk : in std_logic;
			i_reset_n : in std_logic;
			i_enable : in std_logic;
			i_flag : in std_logic;
			i_start_condition : in std_logic;
			i_stop_condition : in std_logic;
			i_enable_ack : in std_logic;
			i_data : in std_logic_vector(7 downto 0);
			io_sda : inout std_logic;
			io_scl : inout std_logic;
			o_q : out std_logic_vector(7 downto 0);
			o_status : out std_logic_vector(4 downto 0);
			o_busy : out std_logic;
			o_ack_error : out std_logic
		);
	end component;
	
	type state_t is (idle, start_read, addr_for_read1, cmd_for_read, restart, addr_for_read2, read_data, start_write, addr_for_write, cmd_for_write, write_data, wait_after_write, ready, stopping);
	
	signal s_state : state_t := idle;
	signal s_start : std_logic := '0';
	signal s_stop : std_logic := '0';
	signal s_busy : std_logic;
	signal s_addr : std_logic_vector(6 downto 0) := 7x"00";
	signal s_cmd : std_logic_vector(7 downto 0) := x"00";
	signal s_data : std_logic_vector(7 downto 0) := x"00";
	signal s_buffer : std_logic_vector(7 downto 0) := x"00";
	signal s_transition : boolean;
	signal s_wait_counter : integer range 0 to WAIT_TIMEOUT := 0;
	signal s_cmd_enable : std_logic;
	signal s_enable : std_logic := '0';
begin
	i2c_cmp : i2c generic map ( input_clk => CLK_SPEED ) port map
	(
		i_clk => i_clk,
		i_reset_n => i_reset_n,
		i_enable => '1',
		i_flag => s_cmd_enable,
		i_start_condition => s_start,
		i_stop_condition => s_stop,
		i_enable_ack => '0',
		i_data => s_buffer,
		io_sda => io_sda,
		io_scl => io_scl,
		o_q => o_q,
		o_busy => s_busy,
		o_ack_error => o_ack_error
	);
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			s_enable <= '0';
		
			if i_reset_n = '0' then
				s_state <= idle;
				s_wait_counter <= 0;
				s_addr <= 7x"00";
				s_cmd <= x"00";
				s_data <= x"00";
				s_buffer <= x"00";
				s_start <= '0';
			else
				if (s_wait_counter /= 0) then
					s_wait_counter <= s_wait_counter - 1;
				end if;
				
				if s_transition then
					case s_state is
					
						when idle =>
							if i_enable = '1' then
								if i_active = '1' then
									if i_read_not_write = '1' then
										s_state <= start_read;
									else
										s_state <= start_write;
									end if;

									s_addr <= i_addr(7 downto 1);
									s_cmd <= i_cmd;
									s_data <= i_data;
									s_start <= '1';
									s_enable <= '1';
								end if;
							end if;
							
						when ready =>
							if i_enable = '1' then
								if i_active = '1' then
									if i_read_not_write = '1' then
										s_state <= start_read;
									else
										s_state <= start_write;
									end if;

									s_addr <= i_addr(7 downto 1);
									s_cmd <= i_cmd;
									s_data <= i_data;
									s_start <= '1';
									s_enable <= '1';
								else
									s_stop <= '1';
									s_enable <= '1';
									s_state <= stopping;
								end if;
							end if;
							
						when stopping =>
							s_stop <= '0';
							s_state <= idle;
						
						when start_read =>
							s_start <= '0';
							s_buffer <= s_addr & '0';
							s_state <= addr_for_read1;
							s_enable <= '1';

						when addr_for_read1 =>
							s_buffer <= s_cmd;
							s_state <= cmd_for_read;
							s_enable <= '1';

						when cmd_for_read =>
							s_start <= '1';
							s_state <= restart;
							s_enable <= '1';
							
						when restart =>
							s_start <= '0';
							s_buffer <= s_addr & '1';
							s_state <= addr_for_read2;
							s_enable <= '1';

						when addr_for_read2 =>
							s_state <= read_data;
							s_enable <= '1';

						when read_data =>
							s_state <= ready;
						
						when start_write =>
							s_start <= '0';
							s_buffer <= s_addr & '0';
							s_state <= addr_for_write;
							s_enable <= '1';

						when addr_for_write =>
							s_buffer <= s_cmd;
							s_state <= cmd_for_write;
							s_enable <= '1';

						when cmd_for_write =>
							s_buffer <= s_data;
							s_state <= write_data;
							s_enable <= '1';

						when write_data =>
							s_wait_counter <= WAIT_TIMEOUT; -- Nach einem Schreibkommando je 7 ms auf EE2 warten
							s_state <= wait_after_write;

						when wait_after_write =>
							if s_wait_counter = 0 then
								s_state <= ready;
							end if;
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	s_cmd_enable <= '0' when s_state = wait_after_write else s_enable;
	s_transition <= (s_wait_counter = 0) when s_state = wait_after_write else (s_busy = '0') and (s_enable = '0');
	o_busy <= '0' when (s_state = idle) or (s_state = ready) else '1';
	
end behavioral;
