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

-- inspired by http://opencores.org/project,i2c

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity i2c is
	generic
	(
		input_clk : integer := 50_000_000;			-- input clock speed from user logic in Hz
		bus_clk : integer := 400_000					-- speed the i2c bus (scl) will run at in Hz
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
end i2c;

architecture behavioral of i2c is
	constant divider: integer := (input_clk / bus_clk) / 4; --number of clocks in 1/4 cycle of scl

	type state_t is (starting1, starting2, started, restarting1, restarting2, write_addr_for_read, write_addr_for_write, await_ack1, await_ack2, await_ack3, await_ack4, await_ack5, await_ack6, write_ack1, write_ack2, addr_written_for_write, addr_written_for_read, read_data, prepare_read, write_data, stopping1, stopping2, stopped);

	signal s_state : state_t := stopped;
	signal s_data_clk : std_logic;
	signal s_data_clk_prev : std_logic;
	signal s_scl_clk : std_logic;
	signal s_sda : std_logic := '1';
	signal s_scl : std_logic := '1';
	signal s_scl_enable : std_logic := '0';
	signal s_scl_int : std_logic;
	signal s_busy : std_logic;
	signal s_ack : std_logic := '0';
	signal s_buffer : std_logic_vector(7 downto 0);
	signal s_q : std_logic_vector(7 downto 0) := x"00";
	signal s_index : integer range 0 to 7 := 7;
	signal s_stretch : std_logic := '0';
	signal s_status : std_logic_vector(4 downto 0) := "00000";
	signal s_ack_error :std_logic := '0';

begin

	-- generate the timing for the bus clock (s_scl_clk) and the data clock (data_clk)
	process (i_clk)
		variable count: integer range 0 to divider * 4;  -- timing for clock generation
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then								-- reset asserted
				s_stretch <= '0';
				count := 0;
			else
				s_data_clk_prev <= s_data_clk;

				if count = divider * 4 - 1 then				-- end of timing cycle
					count := 0;										-- reset timer
				elsif s_stretch = '0' then						-- clock stretching from slave not detected
					count := count + 1;							-- continue clock generation timing
				end if;

				case count is
					when 0 to divider - 1 =>					-- first 1/4 cycle of clocking
						s_scl_clk <= '0';
						s_data_clk <= '0';

					when divider to divider * 2 - 1 =>		-- second 1/4 cycle of clocking
						s_scl_clk <= '0';
						s_data_clk <= '1';

					when divider * 2 to divider * 3 - 1 =>	-- third 1/4 cycle of clocking
						s_scl_clk <= '1';							-- release scl
						
						/*
						if io_scl = '0' then						-- detect if slave is stretching clock
							s_stretch <= '1';
						else
							s_stretch <= '0';
						end if;
						*/
						s_stretch <= '0';

						s_data_clk <= '1';

					when others =>									-- last 1/4 cycle of clocking
						s_scl_clk <= '1';
						s_data_clk <= '0';

				end case;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sda <= '1';
				s_scl <= '1';
				s_state <= stopped;
				s_scl_enable <= '0';
				s_ack_error <= '0';
			else
				if i_flag = '1' then
					if s_busy = '0' then
						if i_start_condition = '1' then
							case s_state is

								when stopped =>
									s_state <= starting1;

								when others =>
									s_state <= restarting1;

							end case;
						elsif i_stop_condition = '1' then
							s_state <= stopping1;
						else
							case s_state is

								when started =>
									if i_data(0) = '1' then
										s_state <= write_addr_for_read;
									else
										s_state <= write_addr_for_write;
									end if;

									s_buffer <= i_data;
									s_index <= 7;
									
								when addr_written_for_write =>
									s_state <= write_data;
									s_buffer <= i_data;
									s_index <= 7;
									
								when addr_written_for_read =>
									s_state <= prepare_read;
									s_ack <= i_enable_ack;
									
								when others =>
									null;

							end case;
						end if;
					end if;
				end if;
				
				if (s_data_clk = '1') and (s_data_clk_prev = '0') then
					case s_state is

						when starting2 =>
							s_scl <= '0';
							s_scl_enable <= '0';
							s_state <= started;
							s_status <= "00001";
							
						when restarting1 =>
							s_sda <= '1';
							s_scl_enable <= '1';
							s_state <= restarting2;
							
						when restarting2 =>
							s_scl <= '0';
							s_scl_enable <= '0';
							s_state <= started;
							s_status <= "00010";
							
						when stopping1 =>
							s_sda <= '0';
							s_scl_enable <= '1';
							s_state <= stopping2;
							
						when write_addr_for_read =>
							s_scl_enable <= '1';
							s_sda <= s_buffer(s_index);
							
							if s_index = 0 then
								s_state <= await_ack5;
							else
								s_index <= s_index - 1;
							end if;

						when write_addr_for_write =>
							s_scl_enable <= '1';
							s_sda <= s_buffer(s_index);
							
							if s_index = 0 then
								s_state <= await_ack1;
							else
								s_index <= s_index - 1;
							end if;
							
						when write_data =>
							s_scl_enable <= '1';
							s_sda <= s_buffer(s_index);
							
							if s_index = 0 then
								s_state <= await_ack3;
							else
								s_index <= s_index - 1;
							end if;
							
						when await_ack1 =>
							s_sda <= '1';
							s_state <= await_ack2;
							
						when await_ack2 =>
							s_sda <= '0';
							s_scl <= '0';
							s_scl_enable <= '0';
							s_state <= addr_written_for_write;
							
						when await_ack3 =>
							s_sda <= '1';
							s_state <= await_ack4;
							
						when await_ack4 =>
							s_sda <= '0';
							s_scl <= '0';
							s_scl_enable <= '0';
							s_state <= addr_written_for_write;
							
						when await_ack5 =>
							s_sda <= '1';
							s_state <= await_ack6;
							
						when await_ack6 =>
							s_sda <= '0';
							s_scl <= '0';
							s_scl_enable <= '0';
							s_state <= addr_written_for_read;
							
						when prepare_read =>
							s_index <= 7;
							s_sda <= '1';
							s_scl_enable <= '1';
							s_state <= read_data;
							
						when write_ack1 =>
							s_sda <= not s_ack;
							s_state <= write_ack2;
							
						when write_ack2 =>
							s_sda <= '0';
							s_scl <= '0';
							s_scl_enable <= '0';
							s_state <= addr_written_for_read;
							s_status <= "0101" & not s_ack;
							
						when others =>
							null;

					end case;
				elsif (s_data_clk = '0') and (s_data_clk_prev = '1') then
					case s_state is
						
						when starting1 =>
							s_sda <= '0';
							s_scl_enable <= '1';
							s_state <= starting2;
							
						when restarting2 =>
							s_sda <= '0';
							
						when stopping2 =>
							s_sda <= '1';
							s_scl <= '1';
							s_scl_enable <= '0';
							s_state <= stopped;
							s_status <= "00000";
							
						when await_ack2 =>
							s_status <= "00" & io_sda & not io_sda & not io_sda;
							
							if io_sda = '1' then
								s_ack_error <= '1';
							end if;
							
						when await_ack4 =>
							s_status <= "001" & io_sda & not io_sda;
							
							if io_sda = '1' then
								s_ack_error <= '1';
							end if;
							
						when await_ack6 =>
							s_status <= "0100" & io_sda;
							
							if io_sda = '1' then
								s_ack_error <= '1';
							end if;
							
						when read_data =>
							if s_index = 0 then
								s_state <= write_ack1;
							else
								s_index <= s_index - 1;
							end if;
						
							s_q <= s_q(6 downto 0) & io_sda;
							
						when others =>
							null;

					end case;
				end if;
			end if;
			
			if s_scl_enable = '1' then
				s_scl_int <= s_scl_clk;
			else
				s_scl_int <= s_scl;
			end if;
		end if;
	end process;
		
	with s_state select s_busy <=
		'0' when started,
		'0' when stopped,
		'0' when addr_written_for_read,
		'0' when addr_written_for_write,
		'1' when others;

	o_q <= s_q;
	o_status <= s_status;
	o_ack_error <= s_ack_error;
	o_busy <= s_busy;
	io_scl <= '0' when (s_scl_int = '0') and (i_enable = '1') else 'Z';
	io_sda <= '0' when (s_sda = '0') and (i_enable = '1') else 'Z';

end behavioral;
