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

package common is

	type flags_t is record
		n : std_logic;
		v : std_logic;
		d : std_logic;
		i : std_logic;
		z : std_logic;
		c : std_logic;
	end record;
	
	type mode_t is (imp, imm, acc, zpn, zpx, zpy, abn, abx, aby, inx, iny, ind, rel);
	type instruction_t is (unk, nop, lda, ldx, ldy, tax, tay, txa, tya, tsx, txs, clc, cli, clv, cld, secr, sed, sei, adc, sbc, inc, inx, iny, dec, dex, dey, cpx, cpy, bcc, bcs, beq, bne, bmi, bpl, bvc, bvs, jsr, rts, rti, ora, and_i, eor, cmp, sta, stx, sty, pha, php, pla, plp, rol_i, ror_i, lsr, asl, jmp, bit_i, brk);
	
	type pc_op_t is (nop, inc, split, pla, pha, daq, enb);
	type in_op_t is (nop, ena, alq, ald, fff);
	type out_op_t is (nop, ena, din, pch, pcl, arg, xrg, yrg, flg);
	type reg_op_t is (nop, arg, xrg, yrg, srg);
	type alu_op_t is (psa, add, adc, sub, sbc, ada, ora, eor, rla, rra, lsr, asl);
	type addr_op_t is (nop, zaq, daq, aqd, div, oaq, oad, zvl, adv, vaq);
	type ctrl_op_t is (nop, alc, bcc, bcs, beq, bne, bmi, bpl, bvc, bvs, don);
	type flags_op_t is (nop, din, nz, nzc, nzv, nvzc, clc, cli, clv, cld, stc, sed, sei);
	type alu_inp_t is (din, val, arg, xrg, yrg, srg, one, pcl, pch, aci, alq, auc, brk);
	
	type video_mode_t is (ntsc, pal);

	-- Constants
	constant N_FLAG : integer := 7;
	constant V_FLAG : integer := 6;
	constant D_FLAG : integer := 3;
	constant I_FLAG : integer := 2;
	constant Z_FLAG : integer := 1;
	constant C_FLAG : integer := 0;

	-- Functions
	function to_std_logic_vector(a: flags_t; b: std_logic) return std_logic_vector;
	function reverse_vector(a: in std_logic_vector) return std_logic_vector;
		
end common;

package body common is

	function to_std_logic_vector(a: flags_t; b: std_logic) return std_logic_vector is
	begin
		return a.n & a.v & '1' & b & a.d & a.i & a.z & a.c;
	end;
	
	function reverse_vector(a: in std_logic_vector) return std_logic_vector is
		variable result: std_logic_vector(a'range);
		alias aa: std_logic_vector(a'reverse_range) is a;
	begin
		for i in aa'range loop
			result(i) := aa(i);
		end loop;

		return result;
	end;
	
end package body;
