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

entity periphery_ctrl is
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
end periphery_ctrl;

architecture behavioral of periphery_ctrl is
	component i2c_master is
		generic
		(
			CLK_SPEED : integer := 50_000_000;
			WAIT_TIMEOUT : integer := 349999
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
	end component;
	
	type state_t is (boot, idle, intr);
	
	constant ADV7513 : std_logic_vector(7 downto 0) := x"72";
	constant SSM2603 : std_logic_vector(7 downto 0) := x"34";

	signal s_state : state_t:= boot;
	signal s_counter : integer range 0 to 50 := 0;
	signal s_enable : std_logic;
	signal s_update : std_logic := '1';
	signal s_active : std_logic;
	signal s_busy : std_logic;
	signal s_addr : std_logic_vector(7 downto 0);
	signal s_cmd : std_logic_vector(7 downto 0);
	signal s_data : std_logic_vector(7 downto 0);
	signal s_q : std_logic_vector(7 downto 0);
	signal s_read_not_write : std_logic;
	signal s_hpd_active : boolean := false;
	signal s_div : integer range 0 to 999 := 0; -- @todo remove wait timeout
begin

	i2c : i2c_master generic map ( CLK_SPEED => CLK_SPEED, WAIT_TIMEOUT => 349999 ) port map
	(
		i_clk => i_clk,
		i_reset_n => i_reset_n,
		i_enable => s_enable and s_update,
		i_active => s_active,
		i_addr => s_addr,
		i_cmd => s_cmd,
		i_data => s_data,
		i_read_not_write => s_read_not_write,
		io_sda => io_sda,
		io_scl => io_scl,
		o_q => s_q,
		o_busy => s_busy,
		o_ack_error => o_ack_error
	);
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_div <= 1;
			elsif s_div = 999 then
				s_div <= 0;
			else
				s_div <= s_div + 1;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			s_update <= '0';
		
			if i_reset_n = '0' then
				s_state <= boot;
				s_counter <= 0;
				s_update <= '1';
				s_hpd_active <= false;
			elsif (s_update = '0') and (s_busy = '0') and (s_div = 999) then
				case s_state is
				
					when idle =>
						if i_int_n = '0' then
							s_state <= intr;
							s_update <= '1';
							s_counter <= 0;
						end if;
						
					when boot =>
						s_update <= '1';
						
						case s_counter is
							
							when 13 =>
								s_state <= intr;
								s_counter <= 1;
								s_hpd_active <= true;
						
							when others =>
								s_counter <= s_counter + 1;
								
						end case;
						
				
					when intr =>
						s_update <= '1';
					
						case s_counter is
						
							when 0 =>
								s_counter <= 1;
								s_hpd_active <= s_q(7) = '1';
						
							when 6 =>
								if s_hpd_active then
									s_counter <= 7;
								else
									s_counter <= 49;
								end if;
						
							when 7 =>
								if (s_q(5) = '1') or (s_q(6) = '1') then
									s_counter <= 8;
								else
									s_counter <= 49;
								end if;
						
							when 50 =>
								s_state <= idle;
						
							when others =>
								s_counter <= s_counter + 1;
						
						end case;
				
					when others =>
					
				end case;
			end if;
		end if;
	end process;
	
	process (s_state, s_counter, s_q)
		procedure write(addr : std_logic_vector(7 downto 0); cmd : std_logic_vector(7 downto 0); data : std_logic_vector(7 downto 0)) is
		begin
			s_enable <= '1';
			s_active <= '1';
			s_addr <= addr;
			s_cmd <= cmd;
			s_data <= data;
			s_read_not_write <= '0';
		end;
		
		procedure read(addr : std_logic_vector(7 downto 0); cmd : std_logic_vector(7 downto 0)) is
		begin
			s_enable <= '1';
			s_active <= '1';
			s_addr <= addr;
			s_cmd <= cmd;
			s_data <= (others => '-');
			s_read_not_write <= '1';
		end;
		
		procedure nop is
		begin
			s_enable <= '0';
			s_active <= '-';
			s_addr <= (others => '-');
			s_cmd <= (others => '-');
			s_data <= (others => '-');
			s_read_not_write <= '-';
		end;
		
		procedure stop is
		begin
			s_enable <= '1';
			s_active <= '0';
			s_addr <= (others => '-');
			s_cmd <= (others => '-');
			s_data <= (others => '-');
			s_read_not_write <= '-';
		end;
	begin
		case s_state is
		
			when boot =>
				case s_counter is
					
					when 0 => nop;
					when 1 => write(SSM2603, x"1E", x"00"); -- Reset
					when 2 => write(SSM2603, x"0C", x"10"); -- power on everything except out
					when 3 => write(SSM2603, x"00", x"40"); -- left input: Mute
					when 4 => write(SSM2603, x"02", x"40"); -- right input: Mute
					when 5 => write(SSM2603, x"04", x"65"); -- left output: -20 dB
					when 6 => write(SSM2603, x"06", x"65"); -- right output: -20 dB
					when 7 => write(SSM2603, x"08", x"D4"); -- analog path
					when 8 => write(SSM2603, x"0A", x"04"); -- digital path
					when 9 => write(SSM2603, x"0E", x"01"); -- digital IF
					when 10 => write(SSM2603, x"10", x"20"); -- sampling rate
					when 11 => write(SSM2603, x"0C", x"00"); -- power on everything
					when 12 => write(SSM2603, x"12", x"01"); -- activate
					when 13 => stop;
					when others => nop;

				end case;
		
			when intr =>
				case s_counter is
				
					when 0 => read(ADV7513, x"96"); -- read HPD-Interrupt status
					when 1 => write(ADV7513, x"92", x"00"); -- deactivate all interrupts
					when 2 => write(ADV7513, x"94", x"00"); -- deactivate all interrupts
					when 3 => write(ADV7513, x"95", x"00"); -- deactivate all interrupts
					when 4 => write(ADV7513, x"93", x"FF"); -- clear all pending interrupts
					when 5 => write(ADV7513, x"96", x"FF"); -- clear all pending interrupts
					when 6 => write(ADV7513, x"97", x"FF"); -- clear all pending interrupts
					when 7 => read(ADV7513, x"42"); -- read status register
					when 8 => read(ADV7513, x"41"); -- configure power register
					when 9 => write(ADV7513, x"41", s_q(7) & '0' & s_q(5 downto 0));
					when 10 => write(ADV7513, x"98", x"03"); -- write fixed register 0x98
					when 11 => write(ADV7513, x"99", x"02"); -- write fixed register 0x99
					when 12 => read(ADV7513, x"9A"); -- write fixed register 0x9A
					when 13 => write(ADV7513, x"9A", "1110000" & s_q(0));
					when 14 => write(ADV7513, x"9C", x"30"); -- write fixed register 0x9D
					when 15 => read(ADV7513, x"9D"); -- write fixed register 0x9A
					when 16 => write(ADV7513, x"9D", s_q(7 downto 2) & "01");
					when 17 => write(ADV7513, x"A2", x"A4"); -- write fixed register 0xA2
					when 18 => write(ADV7513, x"A3", x"A4"); -- write fixed register 0xA3
					when 19 => write(ADV7513, x"A5", x"44"); -- write fixed register 0xA5
					when 20 => write(ADV7513, x"AB", x"40"); -- write fixed register 0xAB
					when 21 => write(ADV7513, x"E0", x"D0"); -- write fixed register 0xE0
					when 22 => write(ADV7513, x"D1", x"FF"); -- write fixed register 0xD1
					when 23 => write(ADV7513, x"DE", x"9C"); -- write fixed register 0x9C
					when 24 => write(ADV7513, x"DE", x"9C"); -- configure ID
					when 25 => write(ADV7513, x"15", x"00"); -- I2S Sampling Frequency = 44.1 kHz, Input ID = RGB 4:4:4
					when 26 => read(ADV7513, x"16"); -- configure Video Input 1
					when 27 => write(ADV7513, x"16", '0' & s_q(6) & "1100" & s_q(1) & '0'); -- OutFormat = 4:4:4, ColorDepth = 8 Bit, InputStyle = Invalid, ColorSpace
					when 28 => read(ADV7513, x"17"); -- configure Video Input 2
					when 29 => write(ADV7513, x"17", s_q(7 downto 2) & '0' & s_q(0)); -- AspectRatio = 4:3
					when 30 => read(ADV7513, x"18"); -- configure CSC
					when 31 => write(ADV7513, x"18", '0' & s_q(6 downto 0));
					when 32 => read(ADV7513, x"AF"); -- configure HDMI
					when 33 => write(ADV7513, x"AF", '0' & s_q(6 downto 2) & '1' & s_q(0)); -- deactivate HDCP, HDMI-Modus
					when 34 => read(ADV7513, x"40"); -- configure Packet Enable
					when 35 => write(ADV7513, x"40", '1' & s_q(6 downto 0));
					when 36 => read(ADV7513, x"4C"); -- configure GC
					when 37 => write(ADV7513, x"4C", s_q(7 downto 4) & "0100");
					when 38 => write(ADV7513, x"01", x"00"); -- Audio: write N to Register 0x01
					when 39 => write(ADV7513, x"02", x"18"); -- Audio: write N to Register 0x02
					when 40 => write(ADV7513, x"03", x"00"); -- Audio: write N to Register 0x03
					when 41 => write(ADV7513, x"0A", x"01"); -- Audio Register 0x0A: CTS Automatic, I2S, 256xfs
					when 42 => write(ADV7513, x"0B", x"2E"); -- Audio Register 0x0B: SCLK rising edge, external MCLK
					when 43 => write(ADV7513, x"0C", x"06"); -- Audio Register 0x0C: Samling frequency from I2S stream, I2S0 enabled, Left justified mode
					when 44 => write(ADV7513, x"12", x"00"); -- Audio Register 0x12: Not Copy protected
					when 45 => write(ADV7513, x"14", x"02"); -- Audio Register 0x14: Audio Word Length = 16 bits
					when 46 => write(ADV7513, x"73", x"02"); -- Audio: InfoFrame Register 0x73: 2 Channels
					when 47 => write(ADV7513, x"76", x"00"); -- Audio: Speaker Mapping
					when 48 => write(ADV7513, x"77", x"78"); -- Audio-InfoFrame: -15dB @todo Seems to have no effect
					when 49 => write(ADV7513, x"94", x"80"); -- activate HPD-Interrupt
					when 50 => stop;
					when others => nop;
				
				end case;
		
			when others => nop;
		
		end case;
	end process;

	o_status <= std_logic_vector(to_unsigned(s_counter, 8));

end behavioral;
