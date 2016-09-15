library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity master_ctrl is
	port
	(
		i_clk : in std_logic;
		i_reset_n : in std_logic := '1';
		i_video_mode : in video_mode_t;
		i_mode_change : in std_logic;
		i_reconfig_data : in std_logic_vector(31 downto 0) := (others => '0');
		o_reconfig_read : out std_logic;
		o_reconfig_write : out std_logic;
		o_reconfig_addr : out std_logic_vector(5 downto 0);
		o_reconfig_new_data : out std_logic_vector(31 downto 0)
	);
end master_ctrl;

architecture behavioral of master_ctrl is
	signal s_reconfig_read : std_logic := '0';
	signal s_reconfig_write : std_logic := '0';
	signal s_reconfig_addr : std_logic_vector(5 downto 0) := (others => '0');
	signal s_reconfig_new_data : std_logic_vector(31 downto 0) := (others => '0');
	signal s_m_counter : std_logic_vector(17 downto 0);
	signal s_n_counter : std_logic_vector(17 downto 0);
	signal s_c_counter : std_logic_vector(17 downto 0);
	signal s_loop_filter_res : std_logic_vector(7 downto 0);
	signal s_write_count : integer range 0 to 2 := 0;
	signal s_enable_d : std_logic_vector(2 downto 0) := (others => '0');
	signal s_state : integer range 0 to 8 := 0;

begin

	process (i_clk)
	begin
	
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_state <= 0;
				s_enable_d <= (others => '0');
				s_write_count <= 0;
				s_reconfig_read <= '0';
				s_reconfig_write <= '0';
				s_reconfig_addr <= (others => '0');
				s_reconfig_new_data <= (others => '0');
			else
				s_enable_d <= s_enable_d(1 downto 0) & i_mode_change;
				
				case s_state is
				
					when 0 => /* idle */
						if (s_enable_d(2) = '0') and (s_enable_d(1) = '1') then
							s_state <= 1;
							s_write_count <= 0;
							s_reconfig_addr <= 6x"0"; /* polling mode */
							s_reconfig_new_data <= 32x"1";
						end if;
						
					when 1 => /* polling mode */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 2;
								s_reconfig_addr <= 6x"4"; /* M counter */
								s_reconfig_new_data <= 14x"0" & s_m_counter;
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 2 => /* writing M counter */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 3;
								s_reconfig_addr <= 6x"3"; /* N counter */
								s_reconfig_new_data <= 14x"0" & s_n_counter;
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 3 => /* writing N counter */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 4;
								s_reconfig_addr <= 6x"5"; /* C counter */
								s_reconfig_new_data <= 14x"0" & s_c_counter;
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 4 => /* writing C counter */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 5;
								s_reconfig_addr <= 6x"8"; /* Loop Filter Resistance */
								s_reconfig_new_data <= 24x"0" & s_loop_filter_res;
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 5 => /* writing Loop Filter Resistance */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 6;
								s_reconfig_addr <= 6x"9"; /* Charge Pump */
								s_reconfig_new_data <= 32x"2";
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 6 => /* writing Charge Pump */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 7;
								s_reconfig_addr <= 6x"2"; /* Start reconfiguration */
								s_reconfig_new_data <= 32x"1";
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 7 => /* starting reconfiguration */
						case s_write_count is
						
							when 0 =>
								s_reconfig_write <= '1';
								
							when 1 =>
								s_reconfig_write <= '0';
								
							when 2 =>
								s_write_count <= 0;
								s_state <= 8;
								s_reconfig_addr <= 6x"1"; /* Status Check */
						
						end case;
						
						s_write_count <= s_write_count + 1;
						
					when 8 => /* checking status */
						if (s_reconfig_read = '1') and (i_reconfig_data(0) = '1') then
							s_reconfig_read <= '0';
							s_state <= 0;
						else
							s_reconfig_read <= '1';
						end if;

				end case;
			
			end if;
		end if;
	
	end process;
	
	process (i_video_mode)
	begin
		case i_video_mode is

			when ntsc =>
				s_m_counter <= 18x"25F5E";
				s_n_counter <= 18x"0505";
				s_c_counter <= 18x"1616";
				s_loop_filter_res <= 8x"3";
				
			when pal =>
				s_m_counter <= 18x"3636";
				s_n_counter <= 18x"20403";
				s_c_counter <= 18x"20F0E";
				s_loop_filter_res <= 8x"4";
			
		end case;
	end process;
	
	o_reconfig_read <= s_reconfig_read;
	o_reconfig_write <= s_reconfig_write;
	o_reconfig_addr <= s_reconfig_addr;
	o_reconfig_new_data <= s_reconfig_new_data;

end;
