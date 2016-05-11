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

from https://eewiki.net/display/LOGIC/IIR+Filter+Design+in+VHDL+Targeted+for+18-Bit,+48+KHz+Audio+Signal+Use
*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------
--	
--			           b0 + b1*Z^-1 + b2*Z^-2
--				H[z] = -------------------------
--						  1 + a1*Z^-1 + a2*Z^-2
--
-------------------------------------------------------------------------	

entity biquad is
	generic
	(
		B0 : std_logic_vector(31 downto 0) := B"01_10_0011_0001_0111_0110_0101_0111_0111";				-- b0		~ +1.548303
		B1 : std_logic_vector(31 downto 0) := B"01_10_0011_0001_0111_0110_0101_0111_0111";				-- b1		~ +1.548303
		B2 : std_logic_vector(31 downto 0) := B"00_00_0000_0000_0000_0000_0000_0000_0000";				-- b2		   0.0	
		A1 : std_logic_vector(31 downto 0) := B"00_10_0011_0001_0111_0110_0101_0111_0111";				-- a1		~ +0.548303
		A2 : std_logic_vector(31 downto 0) := B"00_00_0000_0000_0000_0000_0000_0000_0000"					-- a2		   0.0
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
end biquad;

architecture behavioral of biquad is
	-- define each pre gain sample flip flop
	signal ZFF_X0, ZFF_X1, ZFF_X2, ZFF_Y1, ZFF_Y2 : std_logic_vector(17 downto 0) := (others => '0');

	-- define each post gain 32 but truncated sample
	signal pgZFF_X0, pgZFF_X1, pgZFF_X2, pgZFF_Y1, pgZFF_Y2 : std_logic_vector(17 downto 0) := (others => '0');

	-- define output double reg
	signal Y_out_double : std_logic_vector(17 downto 0) := (others => '0');
	
	-- state machine signals
	type state_type is (idle, run);
	
	signal state_reg : state_type := idle;
	signal state_next : state_type;
	
	-- counter signals
	signal q_reg : unsigned(2 downto 0) := (others => '0');
	signal q_next : unsigned(2 downto 0);
	signal q_reset, q_add : std_logic;

	-- data path flags
	signal mul_coefs, trunc_prods, sum_stg_a, trunc_out : std_logic;

begin

	-- process to shift samples
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				ZFF_X0 <= (others => '0'); 
				ZFF_X1 <= (others => '0'); 
				ZFF_X2 <= (others => '0');
				ZFF_Y1 <= (others => '0'); 
				ZFF_Y2 <= (others => '0');
			elsif i_sample_trig = '1' then
				ZFF_X0 <= i_x(17) & i_x(17 downto 1);
				ZFF_X1 <= ZFF_X0;
				ZFF_X2 <= ZFF_X1;
				ZFF_Y1 <= Y_out_double;								
				ZFF_Y2 <= ZFF_Y1;
			end if;	
		end if;
	end process;
	
	
   -- STATE UPDATE AND TIMING
	process (i_clk) 
   begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				state_reg <= idle;                                    
				q_reg <= (others => '0');                               -- reset counter
			else
				state_reg <= state_next;                                -- update the state
				q_reg <= q_next;
			end if;
		end if;
	end process;

	-- COUNTER FOR TIMING 
	q_next <= (others => '0') when q_reset = '1' else             -- resets the counter 
	          q_reg + 1 when q_add = '1' else                     -- increment count if commanded
	          q_reg;  	
	
	-- process for control of data path flags
	process (q_reg, state_reg, i_sample_trig)
	begin
		-- defaults
		q_reset <= '0';
		q_add <= '0';
		mul_coefs <= '0';
		trunc_prods <= '0';
		sum_stg_a <= '0';
		trunc_out <= '0';
		o_filter_done <= '0';
		
		case state_reg is
		
			when idle =>
				if i_sample_trig = '1' then
					state_next <= run;
				else
					state_next <= idle;
				end if;
				
			when run =>	
				if q_reg < "001" then
					q_add <= '1';
					state_next <= run;
				elsif q_reg < "011" then
					mul_coefs <= '1';
					q_add <= '1';
					state_next <= run;
				elsif q_reg < "100" then
					trunc_prods <= '1';
					q_add <= '1';
					state_next <= run;
				elsif q_reg < "101" then
					sum_stg_a <= '1';
					q_add <= '1';
					state_next <= run;
				elsif q_reg < "110" then
					trunc_out <= '1';
					q_add <= '1';
					state_next <= run;				
				else
					q_reset <= '1';
					o_filter_done <= '1';
					state_next <= idle;
				end if;
			
		end case;
	end process;

	-- truncate the output to summation block
	process (i_clk)
		variable pgZFF_X0_quad : std_logic_vector(49 downto 0) := (others => '0');
		variable pgZFF_X1_quad : std_logic_vector(49 downto 0) := (others => '0');
		variable pgZFF_X2_quad : std_logic_vector(49 downto 0) := (others => '0');
		variable pgZFF_Y1_quad : std_logic_vector(49 downto 0) := (others => '0');
		variable pgZFF_Y2_quad : std_logic_vector(49 downto 0) := (others => '0');
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				pgZFF_X0_quad := (others => '0');
				pgZFF_X1_quad := (others => '0');
				pgZFF_X2_quad := (others => '0');
				pgZFF_Y1_quad := (others => '0');
				pgZFF_Y2_quad := (others => '0');
			else
				if mul_coefs = '1' then
					-- add gain factors to numerator of biquad (feed forward path)
					pgZFF_X0_quad := std_logic_vector(signed(B0) * signed(ZFF_X0));
					pgZFF_X1_quad := std_logic_vector(signed(B1) * signed(ZFF_X1));
					pgZFF_X2_quad := std_logic_vector(signed(B2) * signed(ZFF_X2));

					-- add gain factors to denominator of biquad (feed back path)
					pgZFF_Y1_quad := std_logic_vector(signed(A1) * signed(ZFF_Y1));
					pgZFF_Y2_quad := std_logic_vector(signed(A2) * signed(ZFF_Y2));
				end if;
			
				if trunc_prods = '1' then	
					pgZFF_X0 <= pgZFF_X0_quad(47 downto 30);	
					pgZFF_X2 <= pgZFF_X2_quad(47 downto 30);
					pgZFF_X1 <= pgZFF_X1_quad(47 downto 30);
					pgZFF_Y1 <= pgZFF_Y1_quad(47 downto 30);
					pgZFF_Y2 <= pgZFF_Y2_quad(47 downto 30);
				end if;
			end if;
		end if;
	end process;

	-- sum all post gain feedback and feedfoward paths
	-- Y[z] = X[z]*bo + X[z]*b1*Z^-1 + X[z]*b2*Z^-2 - Y[z]*a1*z^-1 + Y[z]*a2*z^-2
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if sum_stg_a = '1' then
				Y_out_double <= std_logic_vector(signed(pgZFF_X0) + signed(pgZFF_X1) + signed(pgZFF_X2) - signed(pgZFF_Y1) - signed(pgZFF_Y2));
			end if;
		end if;
	end process;

	-- output truncation block
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if trunc_out = '1' then
				o_q <= Y_out_double(17 downto 0);
			end if;
		end if;
	end process;
	
end behavioral;
