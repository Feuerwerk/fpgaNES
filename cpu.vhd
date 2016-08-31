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

-- The sole purpuse for this component is to decode the opcode to be shown
-- in the simulator

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity opcode_decode is
	port
	(
		i_opcode : in std_logic_vector(7 downto 0);
		o_instruction : out instruction_t;
		o_mode : out mode_t
	);
end opcode_decode;

architecture behavioral of opcode_decode is
begin

	process (i_opcode)
	begin
		case i_opcode is
		
			when x"a9" =>
				o_instruction <= lda;
				o_mode <= imm;
				
			when x"a5" =>
				o_instruction <= lda;
				o_mode <= zpn;
				
			when x"b5" =>
				o_instruction <= lda;
				o_mode <= zpx;
				
			when x"ad" =>
				o_instruction <= lda;
				o_mode <= abn;
				
			when x"bd" =>
				o_instruction <= lda;
				o_mode <= abx;
				
			when x"b9" =>
				o_instruction <= lda;
				o_mode <= aby;
				
			when x"a1" =>
				o_instruction <= lda;
				o_mode <= inx;
				
			when x"b1" =>
				o_instruction <= lda;
				o_mode <= iny;
				
			when x"a2" =>
				o_instruction <= ldx;
				o_mode <= imm;
				
			when x"a6" =>
				o_instruction <= ldx;
				o_mode <= zpn;
				
			when x"b6" =>
				o_instruction <= ldx;
				o_mode <= zpy;
				
			when x"ae" =>
				o_instruction <= ldx;
				o_mode <= abn;
				
			when x"be" =>
				o_instruction <= ldx;
				o_mode <= aby;
				
			when x"a0" =>
				o_instruction <= ldy;
				o_mode <= imm;
				
			when x"a4" =>
				o_instruction <= ldy;
				o_mode <= zpn;
				
			when x"b4" =>
				o_instruction <= ldy;
				o_mode <= zpx;
				
			when x"ac" =>
				o_instruction <= ldy;
				o_mode <= abn;
				
			when x"bc" =>
				o_instruction <= ldy;
				o_mode <= abx;
			
			when x"69" =>
				o_instruction <= adc;
				o_mode <= imm;
				
			when x"65" =>
				o_instruction <= adc;
				o_mode <= zpn;
				
			when x"75" =>
				o_instruction <= adc;
				o_mode <= zpx;
				
			when x"6d" =>
				o_instruction <= adc;
				o_mode <= abn;
				
			when x"7d" =>
				o_instruction <= adc;
				o_mode <= abx;
				
			when x"79" =>
				o_instruction <= adc;
				o_mode <= aby;
				
			when x"61" =>
				o_instruction <= adc;
				o_mode <= inx;
				
			when x"71" =>
				o_instruction <= adc;
				o_mode <= iny;

			when x"09" =>
				o_instruction <= ora;
				o_mode <= imm;
				
			when x"05" =>
				o_instruction <= ora;
				o_mode <= zpn;
				
			when x"15" =>
				o_instruction <= ora;
				o_mode <= zpx;
				
			when x"0d" =>
				o_instruction <= ora;
				o_mode <= abn;
				
			when x"1d" =>
				o_instruction <= ora;
				o_mode <= abx;
				
			when x"19" =>
				o_instruction <= ora;
				o_mode <= aby;
				
			when x"01" =>
				o_instruction <= ora;
				o_mode <= inx;
				
			when x"11" =>
				o_instruction <= ora;
				o_mode <= iny;
				
			when x"29" =>
				o_instruction <= and_i;
				o_mode <= imm;
				
			when x"25" =>
				o_instruction <= and_i;
				o_mode <= zpn;
				
			when x"35" =>
				o_instruction <= and_i;
				o_mode <= zpx;
				
			when x"2d" =>
				o_instruction <= and_i;
				o_mode <= abn;
				
			when x"3d" =>
				o_instruction <= and_i;
				o_mode <= abx;
				
			when x"39" =>
				o_instruction <= and_i;
				o_mode <= aby;
				
			when x"21" =>
				o_instruction <= and_i;
				o_mode <= inx;
				
			when x"31" =>
				o_instruction <= and_i;
				o_mode <= iny;
				
			when x"c9" =>
				o_instruction <= cmp;
				o_mode <= imm;
				
			when x"c5" =>
				o_instruction <= cmp;
				o_mode <= zpn;
				
			when x"d5" =>
				o_instruction <= cmp;
				o_mode <= zpx;
				
			when x"cd" =>
				o_instruction <= cmp;
				o_mode <= abn;
				
			when x"dd" =>
				o_instruction <= cmp;
				o_mode <= abx;
				
			when x"d9" =>
				o_instruction <= cmp;
				o_mode <= aby;
				
			when x"c1" =>
				o_instruction <= cmp;
				o_mode <= inx;
				
			when x"d1" =>
				o_instruction <= cmp;
				o_mode <= iny;
				
			when x"85" =>
				o_instruction <= sta;
				o_mode <= zpn;
				
			when x"95" =>
				o_instruction <= sta;
				o_mode <= zpx;
				
			when x"8d" =>
				o_instruction <= sta;
				o_mode <= abn;
				
			when x"9d" =>
				o_instruction <= sta;
				o_mode <= abx;
				
			when x"99" =>
				o_instruction <= sta;
				o_mode <= aby;
				
			when x"81" =>
				o_instruction <= sta;
				o_mode <= inx;
				
			when x"91" =>
				o_instruction <= sta;
				o_mode <= iny;

			when x"49" =>
				o_instruction <= eor;
				o_mode <= imm;
				
			when x"45" =>
				o_instruction <= eor;
				o_mode <= zpn;
				
			when x"55" =>
				o_instruction <= eor;
				o_mode <= zpx;
				
			when x"4d" =>
				o_instruction <= eor;
				o_mode <= abn;
				
			when x"5d" =>
				o_instruction <= eor;
				o_mode <= abx;
				
			when x"59" =>
				o_instruction <= eor;
				o_mode <= aby;
				
			when x"41" =>
				o_instruction <= eor;
				o_mode <= inx;
				
			when x"51" =>
				o_instruction <= eor;
				o_mode <= iny;

			when x"e0" =>
				o_instruction <= cpx;
				o_mode <= imm;
				
			when x"e4" =>
				o_instruction <= cpx;
				o_mode <= zpn;
				
			when x"ec" =>
				o_instruction <= cpx;
				o_mode <= abn;

			when x"c0" =>
				o_instruction <= cpy;
				o_mode <= imm;
				
			when x"c4" =>
				o_instruction <= cpy;
				o_mode <= zpn;
				
			when x"cc" =>
				o_instruction <= cpy;
				o_mode <= abn;

			when x"e8" =>
				o_instruction <= inx;
				o_mode <= imp;
				
			when x"c8" =>
				o_instruction <= iny;
				o_mode <= imp;
			
			when x"aa" =>
				o_instruction <= tax;
				o_mode <= imp;
				
			when x"a8" =>
				o_instruction <= tay;
				o_mode <= imp;
				
			when x"ba" =>
				o_instruction <= tsx;
				o_mode <= imp;
				
			when x"8a" =>
				o_instruction <= txa;
				o_mode <= imp;
				
			when x"9a" =>
				o_instruction <= txs;
				o_mode <= imp;
				
			when x"98" =>
				o_instruction <= tya;
				o_mode <= imp;
				
			when x"18" =>
				o_instruction <= clc;
				o_mode <= imp;
				
			when x"d8" =>
				o_instruction <= cld;
				o_mode <= imp;
				
			when x"58" =>
				o_instruction <= cli;
				o_mode <= imp;
				
			when x"b8" =>
				o_instruction <= clv;
				o_mode <= imp;
				
			when x"38" =>
				o_instruction <= secr;
				o_mode <= imp;
				
			when x"f8" =>
				o_instruction <= sed;
				o_mode <= imp;
				
			when x"78" =>
				o_instruction <= sei;
				o_mode <= imp;

			when x"20" =>
				o_instruction <= jsr;
				o_mode <= abn;
				
			when x"60" =>
				o_instruction <= rts;
				o_mode <= imp;
				
			when x"40" =>
				o_instruction <= rti;
				o_mode <= imp;
				
			when x"90" =>
				o_instruction <= bcc;
				o_mode <= rel;
				
			when x"b0" =>
				o_instruction <= bcs;
				o_mode <= rel;
				
			when x"f0" =>
				o_instruction <= beq;
				o_mode <= rel;
				
			when x"30" =>
				o_instruction <= bmi;
				o_mode <= rel;
				
			when x"d0" =>
				o_instruction <= bne;
				o_mode <= rel;
				
			when x"10" =>
				o_instruction <= bpl;
				o_mode <= rel;
				
			when x"50" =>
				o_instruction <= bvc;
				o_mode <= rel;
				
			when x"70" =>
				o_instruction <= bvs;
				o_mode <= rel;
				
			when x"ea" =>
				o_instruction <= nop;
				o_mode <= imp;
				
			when x"48" =>
				o_instruction <= pha;
				o_mode <= imp;
				
			when x"08" =>
				o_instruction <= php;
				o_mode <= imp;
				
			when x"68" =>
				o_instruction <= pla;
				o_mode <= imp;
				
			when x"28" =>
				o_instruction <= plp;
				o_mode <= imp;
				
			when x"86" =>
				o_instruction <= stx;
				o_mode <= zpn;
				
			when x"96" =>
				o_instruction <= stx;
				o_mode <= zpy;
				
			when x"8e" =>
				o_instruction <= stx;
				o_mode <= abn;

			when x"84" =>
				o_instruction <= sty;
				o_mode <= zpn;
				
			when x"94" =>
				o_instruction <= sty;
				o_mode <= zpx;
				
			when x"8c" =>
				o_instruction <= sty;
				o_mode <= abn;
				
			when x"2a" =>
				o_instruction <= rol_i;
				o_mode <= acc;
				
			when x"26" =>
				o_instruction <= rol_i;
				o_mode <= zpn;
				
			when x"36" =>
				o_instruction <= rol_i;
				o_mode <= zpx;
				
			when x"2e" =>
				o_instruction <= rol_i;
				o_mode <= abn;
				
			when x"3e" =>
				o_instruction <= rol_i;
				o_mode <= abx;
				
			when x"6a" =>
				o_instruction <= ror_i;
				o_mode <= acc;
				
			when x"66" =>
				o_instruction <= ror_i;
				o_mode <= zpn;
				
			when x"76" =>
				o_instruction <= ror_i;
				o_mode <= zpx;
				
			when x"6e" =>
				o_instruction <= ror_i;
				o_mode <= abn;
				
			when x"7e" =>
				o_instruction <= ror_i;
				o_mode <= abx;
				
			when x"4a" =>
				o_instruction <= lsr;
				o_mode <= acc;
				
			when x"46" =>
				o_instruction <= lsr;
				o_mode <= zpn;
				
			when x"56" =>
				o_instruction <= lsr;
				o_mode <= zpx;
				
			when x"4e" =>
				o_instruction <= lsr;
				o_mode <= abn;
				
			when x"5e" =>
				o_instruction <= lsr;
				o_mode <= abx;
				
			when x"0a" =>
				o_instruction <= asl;
				o_mode <= acc;
				
			when x"06" =>
				o_instruction <= asl;
				o_mode <= zpn;
				
			when x"16" =>
				o_instruction <= asl;
				o_mode <= zpx;
				
			when x"0e" =>
				o_instruction <= asl;
				o_mode <= abn;
				
			when x"1e" =>
				o_instruction <= asl;
				o_mode <= abx;
				
			when x"ca" =>
				o_instruction <= dex;
				o_mode <= imp;
				
			when x"88" =>
				o_instruction <= dey;
				o_mode <= imp;
				
			when x"4c" =>
				o_instruction <= jmp;
				o_mode <= abn;
				
			when x"6c" =>
				o_instruction <= jmp;
				o_mode <= ind;
				
			when x"e6" =>
				o_instruction <= inc;
				o_mode <= zpn;
				
			when x"f6" =>
				o_instruction <= inc;
				o_mode <= zpx;
				
			when x"ee" =>
				o_instruction <= inc;
				o_mode <= abn;
				
			when x"fe" =>
				o_instruction <= inc;
				o_mode <= abx;
				
			when x"c6" =>
				o_instruction <= dec;
				o_mode <= zpn;
				
			when x"d6" =>
				o_instruction <= dec;
				o_mode <= zpx;
				
			when x"ce" =>
				o_instruction <= dec;
				o_mode <= abn;
				
			when x"de" =>
				o_instruction <= dec;
				o_mode <= abx;
				
			when x"24" =>
				o_instruction <= bit_i;
				o_mode <= zpn;
				
			when x"2c" =>
				o_instruction <= bit_i;
				o_mode <= abn;
				
			when x"00" =>
				o_instruction <= brk;
				o_mode <= imp;
				
			when x"02" =>
				o_instruction <= rst;
				o_mode <= imp;
				
			when x"03" =>
				o_instruction <= int;
				o_mode <= imp;
				
			when x"04" =>
				o_instruction <= nmi;
				o_mode <= imp;
				
			when x"e9" =>
				o_instruction <= sbc;
				o_mode <= imm;
				
			when x"e5" =>
				o_instruction <= sbc;
				o_mode <= zpn;
				
			when x"f5" =>
				o_instruction <= sbc;
				o_mode <= zpx;
				
			when x"ed" =>
				o_instruction <= sbc;
				o_mode <= abn;
				
			when x"fd" =>
				o_instruction <= sbc;
				o_mode <= abx;
				
			when x"f9" =>
				o_instruction <= sbc;
				o_mode <= aby;
				
			when x"e1" =>
				o_instruction <= sbc;
				o_mode <= inx;
				
			when x"f1" =>
				o_instruction <= sbc;
				o_mode <= iny;
		
			when others =>
				o_instruction <= unk;
				o_mode <= imp;
		
		end case;
	end process;

end;

/***************************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity alu is
	port
	(
		i_op : in alu_op_t;
		i_a : in std_logic_vector(7 downto 0);
		i_b : in std_logic_vector(7 downto 0);
		i_c : in std_logic;
		o_q : out std_logic_vector(8 downto 0)
	);
end alu;

architecture behavioral of alu is
	signal s_sum_n : std_logic_vector(8 downto 0);
	signal s_sum_c : std_logic_vector(8 downto 0);
	signal s_diff_n : std_logic_vector(8 downto 0);
	signal s_diff_c : std_logic_vector(8 downto 0);
begin

	process (all)
	begin
		case i_op is
		
			when psa =>
				o_q <= '0' & i_a;
				
			when add =>
				o_q <= s_sum_n;
				
			when adc =>
				o_q <= s_sum_c;
				
			when sub =>
				o_q <= not s_diff_n(8) & s_diff_n(7 downto 0);
				
			when sbc =>
				o_q <= not s_diff_c(8) & s_diff_c(7 downto 0);
				
			when ada =>
				o_q <= '0' & (i_a and i_b);
				
			when ora =>
				o_q <= '0' & (i_a or i_b);
				
			when eor =>
				o_q <= '0' & (i_a xor i_b);
				
			when rla =>
				o_q <= i_a & i_c;
				
			when rra =>
				o_q <= i_a(0) & i_c & i_a(7 downto 1);
				
			when lsr =>
				o_q <= i_a(0) & '0' & i_a(7 downto 1);
				
			when asl =>
				o_q <= i_a(7 downto 0) & '0';
		
			when others =>
				o_q <= 9x"00";
		
		end case;
	end process;
	
	s_sum_n <= ('0' & i_a) + ('0' & i_b);
	s_sum_c <= s_sum_n + (7x"00" & i_c);
	s_diff_n <= ('0' & i_a) - ('0' & i_b);
	s_diff_c <= s_diff_n - (7x"00" & not i_c);

end;


/***************************************************************/

-- the main component for the 6502 CPU. It doesn't support decimal computation
-- and only the official opcodes. It can be thought as a cylinder music box where
-- the cpu component is the cam with the tone bells an the sequencer component is
-- the cylinder with raised pins to play the bells.
-- inspired by https://github.com/chenxiao07/vhdl-nes

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity cpu is
	port
	(
		i_clk : in std_logic;
		i_ready : in std_logic := '1';
		i_reset_n : in std_logic := '1';
		i_int_n : in std_logic := '1';
		i_nmi_n : in std_logic := '1';
		i_mem_q : in std_logic_vector(7 downto 0) := x"00";
		i_video_mode : in video_mode_t;
		o_mem_addr : out std_logic_vector(15 downto 0);
		o_mem_data : out std_logic_vector(7 downto 0);
		o_mem_write_enable : out std_logic;
		o_phi0 : out std_logic;
		o_phi2 : out std_logic
	);
end cpu;

architecture behavioral of cpu is
	function ze(a: std_logic_vector) return std_logic is
		variable tmp: std_logic := '0';
	begin
		for i in a'range loop
			tmp := tmp or a(i);
		end loop;
	
		return not tmp;
	end;

	component opcode_decode is
		port
		(
			i_opcode : in std_logic_vector(7 downto 0);
			o_instruction : out instruction_t;
			o_mode : out mode_t
		);
	end component;
	component alu is
		port
		(
			i_op : in alu_op_t;
			i_a : in std_logic_vector(7 downto 0);
			i_b : in std_logic_vector(7 downto 0);
			i_c : in std_logic;
			o_q : out std_logic_vector(8 downto 0)
		);
	end component;
	component sequencer is
		port
		(
			i_opcode : in std_logic_vector(7 downto 0);
			i_cycle : in std_logic_vector(2 downto 0);
			o_ctrl_op : out ctrl_op_t;
			o_pc_op : out pc_op_t;
			o_in_op : out in_op_t;
			o_out_op : out out_op_t;
			o_reg_op : out reg_op_t;
			o_flags_op : out flags_op_t;
			o_alu_op : out alu_op_t;
			o_addr_op : out addr_op_t;
			o_alu_a_op : out alu_inp_t;
			o_alu_b_op : out alu_inp_t
		);
	end component;
	
	constant RST_OPCODE : std_logic_vector(7 downto 0) := x"02";
	constant INT_OPCODE : std_logic_vector(7 downto 0) := x"03";
	constant NMI_OPCODE : std_logic_vector(7 downto 0) := x"04";
	
	type opcode_t is (def, rst, int, nmi);

	signal s_mem_addr : std_logic_vector(15 downto 0);
	signal s_mem_data : std_logic_vector(7 downto 0);
	signal s_mem_write_enable : std_logic;
	signal s_cycle : std_logic_vector(2 downto 0) := "000";
	signal s_pc : std_logic_vector(15 downto 0);
	signal s_pc_reg : std_logic_vector(15 downto 0) := x"0400";
	signal s_pc_inc : std_logic_vector(15 downto 0);
	signal s_instruction : instruction_t;
	signal s_mode : mode_t;
	signal s_value : std_logic_vector(7 downto 0) := x"00";
	signal s_opcode : std_logic_vector(7 downto 0);
	signal s_next_opcode : std_logic_vector(7 downto 0);
	signal s_current_opcode : std_logic_vector(7 downto 0) := x"ff";
	signal s_fetch : boolean;
	signal s_fetch_d : boolean := false;
	signal s_new_value : std_logic_vector(7 downto 0) := x"00";
	signal s_write_enable : std_logic := '0';
	signal s_areg : std_logic_vector(7 downto 0) := x"00";
	signal s_xreg : std_logic_vector(7 downto 0) := x"00";
	signal s_yreg : std_logic_vector(7 downto 0) := x"00";
	signal s_sreg : std_logic_vector(7 downto 0) := x"ff";
	signal s_flags : flags_t := ( i => '1', others => '0' );
	signal s_alu_a : std_logic_vector(7 downto 0);
	signal s_alu_b : std_logic_vector(7 downto 0);
	signal s_alu_q : std_logic_vector(8 downto 0);
	signal s_alu_q_d : std_logic_vector(8 downto 0) := 9x"00";
	signal s_addr : std_logic_vector(15 downto 0) := x"0000";
	signal s_overflow : std_logic;
	signal s_alu_carry_input : std_logic_vector(7 downto 0);
	signal s_extended_add : std_logic;
	signal s_branch : std_logic;
	signal s_skip_cycle : boolean;
	signal s_pc_op : pc_op_t;
	signal s_in_op : in_op_t;
	signal s_out_op : out_op_t;
	signal s_reg_op : reg_op_t;
	signal s_flags_op : flags_op_t;
	signal s_alu_op : alu_op_t;
	signal s_addr_op : addr_op_t;
	signal s_ctrl_op : ctrl_op_t;
	signal s_alu_a_op : alu_inp_t;
	signal s_alu_b_op : alu_inp_t;
	signal s_prefetch : boolean := true;
	signal s_int_active : boolean;
	signal s_nmi_active : boolean := false;
	signal s_nmi_last : std_logic := '1';
	signal s_internal_clk : std_logic;
	signal s_sync_clk : std_logic := '0';
	signal s_clk_enable : std_logic;
	signal s_ready_d : std_logic := '1';
	signal s_sync_edge : std_logic;
	signal s_clk_divider : natural := 0;
	signal s_opcode_change : opcode_t := def;
	signal s_mem_q : std_logic_vector(7 downto 0);
	signal s_mem_q_d : std_logic_vector(7 downto 0) := x"00";
	signal s_divider : natural;
	alias s_alu_res : std_logic_vector(7 downto 0) is s_alu_q(7 downto 0);
	alias s_alu_c : std_logic is s_alu_q(8);
	
begin
	opcdec : opcode_decode port map
	(
		i_opcode => s_opcode,
		o_instruction => s_instruction,
		o_mode => s_mode
	);
	alunit : alu port map
	(
		i_op => s_alu_op,
		i_a => s_alu_a,
		i_b => s_alu_b,
		i_c => s_flags.c,
		o_q => s_alu_q
	);
	seq : sequencer port map
	(
		i_opcode => s_opcode,
		i_cycle => s_cycle,
		o_pc_op => s_pc_op,
		o_in_op => s_in_op,
		o_out_op => s_out_op,
		o_reg_op => s_reg_op,
		o_flags_op => s_flags_op,
		o_alu_op => s_alu_op,
		o_addr_op => s_addr_op,
		o_ctrl_op => s_ctrl_op,
		o_alu_a_op => s_alu_a_op,
		o_alu_b_op => s_alu_b_op
	);
	
	-- Clock Divider & Internal Clock
	
	process (i_video_mode)
	begin
		case i_video_mode is
		
			when ntsc =>
				s_divider <= 12;
				
			when pal =>
				s_divider <= 16;
			
		end case;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_clk_divider <= 0;
			elsif s_clk_divider = s_divider - 1 then
				s_clk_divider <= 0;
			else
				s_clk_divider <= s_clk_divider + 1;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_sync_clk <= '0';
			elsif s_clk_divider = 10 then
				s_sync_clk <= '0';
			elsif s_clk_divider = 2 then
				s_sync_clk <= '1';
			end if;
		end if;
	end process;
	
	s_internal_clk <= '1' when s_clk_divider = s_divider - 1 else '0';
	s_clk_enable <= s_internal_clk and i_ready;
	
	-- Memory-Access
	-- Last read memory value is stored if ready-signal drop to 0 and is available until ready returns to 1
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_mem_q_d <= x"00";
			elsif (s_internal_clk = '1') and (s_ready_d = '1') then
				s_mem_q_d <= i_mem_q;
			end if;
		end if;
	end process;
	
	s_mem_q <= i_mem_q when s_ready_d = '1' else s_mem_q_d;
	
	-- Ready-Signal

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				s_ready_d <= '1';
			elsif s_internal_clk = '1' then
				s_ready_d <= i_ready;
			end if;
		end if;
	end process;
	
	-- Detection and Shifting
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_opcode_change <= def;
				elsif s_prefetch then
					s_opcode_change <= rst;
				elsif s_fetch then
					if s_nmi_active then
						s_opcode_change <= nmi;
					elsif s_int_active then
						s_opcode_change <= int;
					else
						s_opcode_change <= def;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_prefetch <= true;
				else
					s_prefetch <= false;
				end if;
			end if;
		end if;
	end process;

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_fetch_d <= false;
				else
					s_fetch_d <= s_fetch;
				end if;
			end if;
		end if;
	end process;
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_alu_q_d <= 9x"00";
				else
					s_alu_q_d <= s_alu_q;
				end if;
			end if;
		end if;
	end process;
	
	-- INT and NMI
	
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_nmi_active <= false;
				elsif (s_nmi_last = '1') and (i_nmi_n = '0') then
					s_nmi_active <= true;
				elsif (s_opcode = NMI_OPCODE) then
					s_nmi_active <= false;
				end if;
				
				s_nmi_last <= i_nmi_n;
			end if;
		end if;
	end process;
	
	s_int_active <= (i_int_n = '0') and (s_flags.i = '0');
	
	-- Cycle

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_cycle <= "000";
				else
					if s_fetch then
						s_cycle <= "000";
					elsif s_skip_cycle then
						s_cycle <= s_cycle + "010";
					else
						s_cycle <= s_cycle + "001";
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- Program-Counter

	with s_pc_op select s_pc <=
		s_mem_q & s_alu_res when daq,
		s_pc_reg when others;
		
	s_pc_inc <= s_pc + x"0001";
		
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_pc_reg <= x"8000";
				elsif s_fetch then
					if s_nmi_active or s_int_active then
						s_pc_reg <= s_pc;
					else
						s_pc_reg <= s_pc_inc;
					end if;
				else
					case s_pc_op is
					
						when inc | daq =>
							s_pc_reg <= s_pc_inc;
							
						when pla =>
							s_pc_reg(7 downto 0) <= s_alu_res;
							
						when pha =>
							s_pc_reg(15 downto 8) <= s_alu_res;
		
						when others =>
							s_pc_reg <= s_pc;
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- Opcode

	process (i_clk, s_clk_enable)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_current_opcode <= x"00";
				elsif s_fetch_d then
					s_current_opcode <= s_opcode;
				end if;
			end if;
		end if;
	end process;
	
	-- Input

	process (i_clk, s_clk_enable)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_value <= x"00";
				else
					case s_in_op is
					
						when ena =>
							s_value <= s_mem_q;
							
						when alq =>
							s_value <= s_alu_res;
							
						when ald =>
							s_value <= s_alu_q_d(7 downto 0);
							
						when fff =>
							s_value <= x"ff";
					
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- Ouput

	with s_out_op select s_new_value <=
		s_mem_q when din,
		s_alu_res when ena,
		s_pc(7 downto 0) when pcl,
		s_pc(15 downto 8) when pch,
		s_areg when arg,
		s_xreg when xrg,
		s_yreg when yrg,
		to_std_logic_vector(s_flags, '1') when flg,
		to_std_logic_vector(s_flags, '0') when flz,
		x"--" when others;
		
	s_write_enable <= '0' when s_out_op = nop else '1';
	
	-- Registers

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_areg <= x"00";
					s_xreg <= x"00";
					s_yreg <= x"00";
					s_sreg <= x"ff";
				else
					case s_reg_op is
					
						when arg =>
							s_areg <= s_alu_res;
							
						when xrg =>
							s_xreg <= s_alu_res;
							
						when yrg =>
							s_yreg <= s_alu_res;
					
						when srg =>
							s_sreg <= s_alu_res;
					
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- I Flag

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_flags.i <= '1';
				else
					case s_flags_op is
					
						when din =>
							s_flags.i <= s_mem_q(I_FLAG);
					
						when sei =>
							s_flags.i <= '1';
							
						when cli =>
							s_flags.i <= '0';
							
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- Z Flag

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_flags.z <= '0';
				else
					case s_flags_op is
					
						when din =>
							s_flags.z <= s_mem_q(Z_FLAG);
					
						when nz | nzv | nzc | nvzc =>
							s_flags.z <= ze(s_alu_res);
							
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- N Flag

	process (i_clk, s_clk_enable)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_flags.n <= '0';
				else
					case s_flags_op is
					
						when din =>
							s_flags.n <= s_mem_q(N_FLAG);
					
						when nz | nzc | nvzc =>
							s_flags.n <= s_alu_res(7);
							
						when nzv =>
							s_flags.n <= s_mem_q(7);
							
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
		
	-- V Flag

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_flags.v <= '0';
				else
					case s_flags_op is
					
						when din =>
							s_flags.v <= s_mem_q(V_FLAG);
					
						when nvzc =>
							s_flags.v <= s_overflow;
							
						when nzv =>
							s_flags.v <= s_mem_q(6);
							
						when clv =>
							s_flags.v <= '0';
							
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- C Flag

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_flags.c <= '0';
				else
					case s_flags_op is
					
						when din =>
							s_flags.c <= s_mem_q(C_FLAG);
					
						when stc =>
							s_flags.c <= '1';
							
						when clc =>
							s_flags.c <= '0';
							
						when nzc | nvzc =>
							s_flags.c <= s_alu_c;
							
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- D Flag

	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if s_clk_enable = '1' then
				if i_reset_n = '0' then
					s_flags.d <= '0';
				else
					case s_flags_op is
					
						when din =>
							s_flags.d <= s_mem_q(D_FLAG);
					
						when sed =>
							s_flags.d <= '1';
							
						when cld =>
							s_flags.d <= '0';
							
						when others =>
					
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- ALU A Register

	with s_alu_a_op select s_alu_a <= 
		s_value when val,
		s_mem_q when din,
		s_alu_q_d(7 downto 0) when alq,
		s_areg when arg,
		s_xreg when xrg,
		s_yreg when yrg,
		s_sreg when srg,
		s_pc(7 downto 0) when pcl,
		s_pc(15 downto 8) when pch,
		s_alu_carry_input when aci,
		7x"0" & s_alu_q_d(8) when auc,
		x"01" when one,
		x"fe" when brk,
		x"fc" when rst,
		x"fa" when nmi,
		x"--" when others;

	-- ALU B Register

	with s_alu_b_op select s_alu_b <= 
		s_value when val,
		s_mem_q when din,
		s_alu_q_d(7 downto 0) when alq,
		s_areg when arg,
		s_xreg when xrg,
		s_yreg when yrg,
		s_sreg when srg,
		s_pc(7 downto 0) when pcl,
		s_pc(15 downto 8) when pch,
		s_alu_carry_input when aci,
		7x"0" & s_alu_q_d(8) when auc,
		x"01" when one,
		x"fe" when brk,
		x"fc" when rst,
		x"fa" when nmi,
		x"--" when others;
	
	-- Addr

	with s_addr_op select s_mem_addr <=
		s_pc when nop,
		x"00" & s_alu_res when zaq,
		x"01" & s_alu_res when oaq,
		x"01" & s_alu_q_d(7 downto 0) when oad,
		x"00" & s_value when zvl,
		s_value & s_alu_res when vaq,
		s_mem_q & s_alu_res when daq,
		s_alu_res & s_alu_q_d(7 downto 0) when aqd,
		s_alu_q_d(7 downto 0) & s_value when adv,
		x"----" when others;

	with s_ctrl_op select s_skip_cycle <=
		(s_alu_c = '0') when alc,
		(s_extended_add = '0') when bcc,
		(s_extended_add = '0') when bcs,
		(s_extended_add = '0') when bne,
		(s_extended_add = '0') when beq,
		(s_extended_add = '0') when bpl,
		(s_extended_add = '0') when bmi,
		(s_extended_add = '0') when bvc,
		(s_extended_add = '0') when bvs,
		false when others;
		
	-- current opcode which has to be executed
	s_opcode <= s_next_opcode when s_fetch_d
	            else s_current_opcode;
					
	with s_opcode_change select s_next_opcode <=
		RST_OPCODE when rst,
	   NMI_OPCODE when nmi,
	   INT_OPCODE when int,
	   s_mem_q when others;

	s_mem_data <= s_new_value;
	s_mem_write_enable <= s_write_enable;
	
	-- is 1 when a signed overflow occured
	s_overflow <= (s_alu_a(7) xnor s_alu_b(7)) and (s_alu_a(7) xor s_alu_res(7)) when (s_alu_op = add) or (s_alu_op = adc)
	              else (s_alu_a(7) xor s_alu_b(7)) and (s_alu_a(7) xor s_alu_res(7)) when (s_alu_op = sub) or (s_alu_op = sbc)
	              else '0';
					 
	-- is 1 when the MSB of a 16-bit addition changed and an additional cycle is needed
	s_extended_add <= (s_alu_b(7) xnor s_alu_res(7)) and (s_alu_b(7) xor s_alu_a(7));
	
	-- input parameter for the ALU when carry for a 16-bit value is needed (e.g. program counter)
	s_alu_carry_input <= s_alu_q_d(7) & s_alu_q_d(7) & s_alu_q_d(7) & s_alu_q_d(7) & s_alu_q_d(7) & s_alu_q_d(7) & s_alu_q_d(7) & '1';

	-- is 1 when branch condition is true but no branching is requested
	with s_ctrl_op select s_branch <=
		not s_flags.c when bcc,
		s_flags.c when bcs,
		not s_flags.z when bne,
		s_flags.z when beq,
		not s_flags.n when bpl,
		s_flags.n when bmi,
		not s_flags.v when bvc,
		s_flags.v when bvs,
		'1' when others;

	-- is 1 when fetching is active in the next cycle
	s_fetch <= s_prefetch or (s_ctrl_op = don) or (s_branch = '0');

	o_mem_addr <= s_mem_addr;
	o_mem_data <= s_mem_data;
	o_mem_write_enable <= s_mem_write_enable;

	s_sync_edge <= i_clk when s_clk_divider = 10 else '1';
	o_phi0 <= s_internal_clk;
	o_phi2 <= s_sync_clk and s_sync_edge;

end;
