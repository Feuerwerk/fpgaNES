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

entity sequencer is
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
		o_alu_b_op : out alu_inp_t;
		o_branch_at_cycle_1 : out boolean;
		o_branch_at_cycle_2 : out boolean
	);
end sequencer;

architecture behavioral of sequencer is
	signal s_addr : std_ulogic_vector(10 downto 0);
begin

	-- Controller
	with s_addr select o_ctrl_op <=
		don when b"0110_1001_001", -- ADC / Immediate
		don when b"0110_0101_010", -- ADC / Zero Page
		don when b"0111_0101_011", -- ADC / Zero Page,X
		don when b"0110_1101_011", -- ADC / Absolute
		alc when b"0111_1101_010", -- ADC / Absolute,X
		don when b"0111_1101_100", -- ADC / Absolute,X
		alc when b"0111_1001_010", -- ADC / Absolute,Y
		don when b"0111_1001_100", -- ADC / Absolute,Y
		don when b"0110_0001_101", -- ADC / (Indirect,X)
		alc when b"0111_0001_011", -- ADC / (Indirect),Y
		don when b"0111_0001_101", -- ADC / (Indirect),Y
		don when b"0010_1001_001", -- AND / Immediate
		don when b"0010_0101_010", -- AND / Zero Page
		don when b"0011_0101_011", -- AND / Zero Page,X
		don when b"0010_1101_011", -- AND / Absolute
		alc when b"0011_1101_010", -- AND / Absolute,X
		don when b"0011_1101_100", -- AND / Absolute,X
		alc when b"0011_1001_010", -- AND / Absolute,Y
		don when b"0011_1001_100", -- AND / Absolute,Y
		don when b"0010_0001_101", -- AND / (Indirect,X)
		alc when b"0011_0001_011", -- AND / (Indirect),Y
		don when b"0011_0001_101", -- AND / (Indirect),Y
		don when b"0000_1010_001", -- ASL / Accumulator
		don when b"0000_0110_100", -- ASL / Zero Page
		don when b"0001_0110_101", -- ASL / Zero Page,X
		don when b"0000_1110_101", -- ASL / Absolute
		don when b"0001_1110_110", -- ASL / Absolute,X
		bcc when b"1001_0000_001", -- BCC / Relative
		don when b"1001_0000_011", -- BCC / Relative
		bcs when b"1011_0000_001", -- BCS / Relative
		don when b"1011_0000_011", -- BCS / Relative
		beq when b"1111_0000_001", -- BEQ / Relative
		don when b"1111_0000_011", -- BEQ / Relative
		don when b"0010_0100_010", -- BIT / Zero Page
		don when b"0010_1100_011", -- BIT / Absolute
		bmi when b"0011_0000_001", -- BMI / Relative
		don when b"0011_0000_011", -- BMI / Relative
		bne when b"1101_0000_001", -- BNE / Relative
		don when b"1101_0000_011", -- BNE / Relative
		bpl when b"0001_0000_001", -- BPL / Relative
		don when b"0001_0000_011", -- BPL / Relative
		don when b"0000_0000_110", -- BRK / Implied
		bvc when b"0101_0000_001", -- BVC / Relative
		don when b"0101_0000_011", -- BVC / Relative
		bvs when b"0111_0000_001", -- BVS / Relative
		don when b"0111_0000_011", -- BVS / Relative
		don when b"0001_1000_001", -- CLC / Implied
		don when b"1101_1000_001", -- CLD / Implied
		don when b"0101_1000_001", -- CLI / Implied
		don when b"1011_1000_001", -- CLV / Implied
		don when b"1100_1001_001", -- CMP / Immediate
		don when b"1100_0101_010", -- CMP / Zero Page
		don when b"1101_0101_011", -- CMP / Zero Page,X
		don when b"1100_1101_011", -- CMP / Absolute
		alc when b"1101_1101_010", -- CMP / Absolute,X
		don when b"1101_1101_100", -- CMP / Absolute,X
		alc when b"1101_1001_010", -- CMP / Absolute,Y
		don when b"1101_1001_100", -- CMP / Absolute,Y
		don when b"1100_0001_101", -- CMP / (Indirect,X)
		alc when b"1101_0001_011", -- CMP / (Indirect),Y
		don when b"1101_0001_101", -- CMP / (Indirect),Y
		don when b"1110_0000_001", -- CPX / Immediate
		don when b"1110_0100_010", -- CPX / Zero Page
		don when b"1110_1100_011", -- CPX / Absolute
		don when b"1100_0000_001", -- CPY / Immediate
		don when b"1100_0100_010", -- CPY / Zero Page
		don when b"1100_1100_011", -- CPY / Absolute
		don when b"1100_0110_100", -- DEC / Zero Page
		don when b"1101_0110_101", -- DEC / Zero Page,X
		don when b"1100_1110_101", -- DEC / Absolute
		don when b"1101_1110_110", -- DEC / Absolute,X
		don when b"1100_1010_001", -- DEX / Implied
		don when b"1000_1000_001", -- DEY / Implied
		don when b"0100_1001_001", -- EOR / Immediate
		don when b"0100_0101_010", -- EOR / Zero Page
		don when b"0101_0101_011", -- EOR / Zero Page,X
		don when b"0100_1101_011", -- EOR / Absolute
		alc when b"0101_1101_010", -- EOR / Absolute,X
		don when b"0101_1101_100", -- EOR / Absolute,X
		alc when b"0101_1001_010", -- EOR / Absolute,Y
		don when b"0101_1001_100", -- EOR / Absolute,Y
		don when b"0100_0001_101", -- EOR / (Indirect,X)
		alc when b"0101_0001_011", -- EOR / (Indirect),Y
		don when b"0101_0001_101", -- EOR / (Indirect),Y
		don when b"1110_0110_100", -- INC / Zero Page
		don when b"1111_0110_101", -- INC / Zero Page,X
		don when b"1110_1110_101", -- INC / Absolute
		don when b"1111_1110_110", -- INC / Absolute,X
		don when b"0000_0011_110", -- INT / Implied
		don when b"1110_1000_001", -- INX / Implied
		don when b"1100_1000_001", -- INY / Implied
		don when b"0100_1100_010", -- JMP / Absolute
		don when b"0110_1100_100", -- JMP / Indirect
		don when b"0010_0000_101", -- JSR / Absolute
		don when b"1010_1001_001", -- LDA / Immediate
		don when b"1010_0101_010", -- LDA / Zero Page
		don when b"1011_0101_011", -- LDA / Zero Page,X
		don when b"1010_1101_011", -- LDA / Absolute
		alc when b"1011_1101_010", -- LDA / Absolute,X
		don when b"1011_1101_100", -- LDA / Absolute,X
		alc when b"1011_1001_010", -- LDA / Absolute,Y
		don when b"1011_1001_100", -- LDA / Absolute,Y
		don when b"1010_0001_101", -- LDA / (Indirect,X)
		alc when b"1011_0001_011", -- LDA / (Indirect),Y
		don when b"1011_0001_101", -- LDA / (Indirect),Y
		don when b"1010_0010_001", -- LDX / Immediate
		don when b"1010_0110_010", -- LDX / Zero Page
		don when b"1011_0110_011", -- LDX / Zero Page,Y
		don when b"1010_1110_011", -- LDX / Absolute
		alc when b"1011_1110_010", -- LDX / Absolute,Y
		don when b"1011_1110_100", -- LDX / Absolute,Y
		don when b"1010_0000_001", -- LDY / Immediate
		don when b"1010_0100_010", -- LDY / Zero Page
		don when b"1011_0100_011", -- LDY / Zero Page,X
		don when b"1010_1100_011", -- LDY / Absolute
		alc when b"1011_1100_010", -- LDY / Absolute,X
		don when b"1011_1100_100", -- LDY / Absolute,X
		don when b"0100_1010_001", -- LSR / Accumulator
		don when b"0100_0110_100", -- LSR / Zero Page
		don when b"0101_0110_101", -- LSR / Zero Page,X
		don when b"0100_1110_101", -- LSR / Absolute
		don when b"0101_1110_110", -- LSR / Absolute,X
		don when b"0000_0100_110", -- NMI / Implied
		don when b"1110_1010_001", -- NOP / Implied
		don when b"0000_1001_001", -- ORA / Immediate
		don when b"0000_0101_010", -- ORA / Zero Page
		don when b"0001_0101_011", -- ORA / Zero Page,X
		don when b"0000_1101_011", -- ORA / Absolute
		alc when b"0001_1101_010", -- ORA / Absolute,X
		don when b"0001_1101_100", -- ORA / Absolute,X
		alc when b"0001_1001_010", -- ORA / Absolute,Y
		don when b"0001_1001_100", -- ORA / Absolute,Y
		don when b"0000_0001_101", -- ORA / (Indirect,X)
		alc when b"0001_0001_011", -- ORA / (Indirect),Y
		don when b"0001_0001_101", -- ORA / (Indirect),Y
		don when b"0100_1000_010", -- PHA / Implied
		don when b"0000_1000_010", -- PHP / Implied
		don when b"0110_1000_011", -- PLA / Implied
		don when b"0010_1000_011", -- PLP / Implied
		don when b"0010_1010_001", -- ROL / Accumulator
		don when b"0010_0110_100", -- ROL / Zero Page
		don when b"0011_0110_101", -- ROL / Zero Page,X
		don when b"0010_1110_101", -- ROL / Absolute
		don when b"0011_1110_110", -- ROL / Absolute,X
		don when b"0110_1010_001", -- ROR / Accumulator
		don when b"0110_0110_100", -- ROR / Zero Page
		don when b"0111_0110_101", -- ROR / Zero Page,X
		don when b"0110_1110_101", -- ROR / Absolute
		don when b"0111_1110_110", -- ROR / Absolute,X
		don when b"0000_0010_011", -- RST / Implied
		don when b"0100_0000_101", -- RTI / Implied
		don when b"0110_0000_101", -- RTS / Implied
		don when b"1110_1001_001", -- SBC / Immediate
		don when b"1110_0101_010", -- SBC / Zero Page
		don when b"1111_0101_011", -- SBC / Zero Page,X
		don when b"1110_1101_011", -- SBC / Absolute
		alc when b"1111_1101_010", -- SBC / Absolute,X
		don when b"1111_1101_100", -- SBC / Absolute,X
		alc when b"1111_1001_010", -- SBC / Absolute,Y
		don when b"1111_1001_100", -- SBC / Absolute,Y
		don when b"1110_0001_101", -- SBC / (Indirect,X)
		alc when b"1111_0001_011", -- SBC / (Indirect),Y
		don when b"1111_0001_101", -- SBC / (Indirect),Y
		don when b"0011_1000_001", -- SEC / Implied
		don when b"1111_1000_001", -- SED / Implied
		don when b"0111_1000_001", -- SEI / Implied
		don when b"1000_0101_010", -- STA / Zero Page
		don when b"1001_0101_011", -- STA / Zero Page,X
		don when b"1000_1101_011", -- STA / Absolute
		don when b"1001_1101_100", -- STA / Absolute,X
		don when b"1001_1001_100", -- STA / Absolute,Y
		don when b"1000_0001_101", -- STA / (Indirect,X)
		don when b"1001_0001_101", -- STA / (Indirect),Y
		don when b"1000_0110_010", -- STX / Zero Page
		don when b"1001_0110_011", -- STX / Zero Page,Y
		don when b"1000_1110_011", -- STX / Absolute
		don when b"1000_0100_010", -- STY / Zero Page
		don when b"1001_0100_011", -- STY / Zero Page,X
		don when b"1000_1100_011", -- STY / Absolute
		don when b"1010_1010_001", -- TAX / Implied
		don when b"1010_1000_001", -- TAY / Implied
		don when b"1011_1010_001", -- TSX / Implied
		don when b"1000_1010_001", -- TXA / Implied
		don when b"1001_1010_001", -- TXS / Implied
		don when b"1001_1000_001", -- TYA / Implied
		nop when others;
		
	-- Program-Counter
	with s_addr select o_pc_op <=
		inc when b"0110_1001_000", -- ADC / Immediate
		inc when b"0110_0101_000", -- ADC / Zero Page
		inc when b"0111_0101_000", -- ADC / Zero Page,X
		inc when b"0110_1101_000", -- ADC / Absolute
		inc when b"0110_1101_001", -- ADC / Absolute
		inc when b"0111_1101_000", -- ADC / Absolute,X
		inc when b"0111_1101_001", -- ADC / Absolute,X
		inc when b"0111_1001_000", -- ADC / Absolute,Y
		inc when b"0111_1001_001", -- ADC / Absolute,Y
		inc when b"0110_0001_000", -- ADC / (Indirect,X)
		inc when b"0111_0001_000", -- ADC / (Indirect),Y
		inc when b"0010_1001_000", -- AND / Immediate
		inc when b"0010_0101_000", -- AND / Zero Page
		inc when b"0011_0101_000", -- AND / Zero Page,X
		inc when b"0010_1101_000", -- AND / Absolute
		inc when b"0010_1101_001", -- AND / Absolute
		inc when b"0011_1101_000", -- AND / Absolute,X
		inc when b"0011_1101_001", -- AND / Absolute,X
		inc when b"0011_1001_000", -- AND / Absolute,Y
		inc when b"0011_1001_001", -- AND / Absolute,Y
		inc when b"0010_0001_000", -- AND / (Indirect,X)
		inc when b"0011_0001_000", -- AND / (Indirect),Y
		inc when b"0000_0110_000", -- ASL / Zero Page
		inc when b"0001_0110_000", -- ASL / Zero Page,X
		inc when b"0000_1110_000", -- ASL / Absolute
		inc when b"0000_1110_001", -- ASL / Absolute
		inc when b"0001_1110_000", -- ASL / Absolute,X
		inc when b"0001_1110_001", -- ASL / Absolute,X
		inc when b"1001_0000_000", -- BCC / Relative
		pla when b"1001_0000_001", -- BCC / Relative
		pha when b"1001_0000_010", -- BCC / Relative
		inc when b"1011_0000_000", -- BCS / Relative
		pla when b"1011_0000_001", -- BCS / Relative
		pha when b"1011_0000_010", -- BCS / Relative
		inc when b"1111_0000_000", -- BEQ / Relative
		pla when b"1111_0000_001", -- BEQ / Relative
		pha when b"1111_0000_010", -- BEQ / Relative
		inc when b"0010_0100_000", -- BIT / Zero Page
		inc when b"0010_1100_000", -- BIT / Absolute
		inc when b"0010_1100_001", -- BIT / Absolute
		inc when b"0011_0000_000", -- BMI / Relative
		pla when b"0011_0000_001", -- BMI / Relative
		pha when b"0011_0000_010", -- BMI / Relative
		inc when b"1101_0000_000", -- BNE / Relative
		pla when b"1101_0000_001", -- BNE / Relative
		pha when b"1101_0000_010", -- BNE / Relative
		inc when b"0001_0000_000", -- BPL / Relative
		pla when b"0001_0000_001", -- BPL / Relative
		pha when b"0001_0000_010", -- BPL / Relative
		enb when b"0000_0000_000", -- BRK / Implied
		daq when b"0000_0000_110", -- BRK / Implied
		inc when b"0101_0000_000", -- BVC / Relative
		pla when b"0101_0000_001", -- BVC / Relative
		pha when b"0101_0000_010", -- BVC / Relative
		inc when b"0111_0000_000", -- BVS / Relative
		pla when b"0111_0000_001", -- BVS / Relative
		pha when b"0111_0000_010", -- BVS / Relative
		inc when b"1100_1001_000", -- CMP / Immediate
		inc when b"1100_0101_000", -- CMP / Zero Page
		inc when b"1101_0101_000", -- CMP / Zero Page,X
		inc when b"1100_1101_000", -- CMP / Absolute
		inc when b"1100_1101_001", -- CMP / Absolute
		inc when b"1101_1101_000", -- CMP / Absolute,X
		inc when b"1101_1101_001", -- CMP / Absolute,X
		inc when b"1101_1001_000", -- CMP / Absolute,Y
		inc when b"1101_1001_001", -- CMP / Absolute,Y
		inc when b"1100_0001_000", -- CMP / (Indirect,X)
		inc when b"1101_0001_000", -- CMP / (Indirect),Y
		inc when b"1110_0000_000", -- CPX / Immediate
		inc when b"1110_0100_000", -- CPX / Zero Page
		inc when b"1110_1100_000", -- CPX / Absolute
		inc when b"1110_1100_001", -- CPX / Absolute
		inc when b"1100_0000_000", -- CPY / Immediate
		inc when b"1100_0100_000", -- CPX / Zero Page
		inc when b"1100_1100_000", -- CPX / Absolute
		inc when b"1100_1100_001", -- CPX / Absolute
		inc when b"1100_0110_000", -- DEC / Zero Page
		inc when b"1101_0110_000", -- DEC / Zero Page,X
		inc when b"1100_1110_000", -- DEC / Absolute
		inc when b"1100_1110_001", -- DEC / Absolute
		inc when b"1101_1110_000", -- DEC / Absolute,X
		inc when b"1101_1110_001", -- DEC / Absolute,X
		inc when b"0100_1001_000", -- EOR / Immediate
		inc when b"0100_0101_000", -- EOR / Zero Page
		inc when b"0101_0101_000", -- EOR / Zero Page,X
		inc when b"0100_1101_000", -- EOR / Absolute
		inc when b"0100_1101_001", -- EOR / Absolute
		inc when b"0101_1101_000", -- EOR / Absolute,X
		inc when b"0101_1101_001", -- EOR / Absolute,X
		inc when b"0101_1001_000", -- EOR / Absolute,Y
		inc when b"0101_1001_001", -- EOR / Absolute,Y
		inc when b"0100_0001_000", -- EOR / (Indirect,X)
		inc when b"0101_0001_000", -- EOR / (Indirect),Y
		inc when b"1110_0110_000", -- INC / Zero Page
		inc when b"1111_0110_000", -- INC / Zero Page,X
		inc when b"1110_1110_000", -- INC / Absolute
		inc when b"1110_1110_001", -- INC / Absolute
		inc when b"1111_1110_000", -- INC / Absolute,X
		inc when b"1111_1110_001", -- INC / Absolute,X
		daq when b"0000_0011_110", -- INT / Implied
		inc when b"0100_1100_000", -- JMP / Absolute
		inc when b"0100_1100_001", -- JMP / Absolute
		daq when b"0100_1100_010", -- JMP / Absolute
		inc when b"0110_1100_000", -- JMP / Indirect
		inc when b"0110_1100_001", -- JMP / Indirect
		daq when b"0110_1100_100", -- JMP / Indirect
		inc when b"0010_0000_000", -- JSR / Absolute
		daq when b"0010_0000_101", -- JSR / Absolute
		inc when b"1010_1001_000", -- LDA / Immediate
		inc when b"1010_0101_000", -- LDA / Zero Page
		inc when b"1011_0101_000", -- LDA / Zero Page,X
		inc when b"1010_1101_000", -- LDA / Absolute
		inc when b"1010_1101_001", -- LDA / Absolute
		inc when b"1011_1101_000", -- LDA / Absolute,X
		inc when b"1011_1101_001", -- LDA / Absolute,X
		inc when b"1011_1001_000", -- LDA / Absolute,Y
		inc when b"1011_1001_001", -- LDA / Absolute,Y
		inc when b"1010_0001_000", -- LDA / (Indirect,X)
		inc when b"1011_0001_000", -- LDA / (Indirect),Y
		inc when b"1010_0010_000", -- LDX / Immediate
		inc when b"1010_0110_000", -- LDX / Zero Page
		inc when b"1011_0110_000", -- LDX / Zero Page,Y
		inc when b"1010_1110_000", -- LDX / Absolute
		inc when b"1010_1110_001", -- LDX / Absolute
		inc when b"1011_1110_000", -- LDX / Absolute,Y
		inc when b"1011_1110_001", -- LDX / Absolute,Y
		inc when b"1010_0000_000", -- LDY / Immediate
		inc when b"1010_0100_000", -- LDY / Zero Page
		inc when b"1011_0100_000", -- LDY / Zero Page,X
		inc when b"1010_1100_000", -- LDY / Absolute
		inc when b"1010_1100_001", -- LDY / Absolute
		inc when b"1011_1100_000", -- LDY / Absolute,X
		inc when b"1011_1100_001", -- LDY / Absolute,X
		inc when b"0100_0110_000", -- LSR / Zero Page
		inc when b"0101_0110_000", -- LSR / Zero Page,X
		inc when b"0100_1110_000", -- LSR / Absolute
		inc when b"0100_1110_001", -- LSR / Absolute
		inc when b"0101_1110_000", -- LSR / Absolute,X
		inc when b"0101_1110_001", -- LSR / Absolute,X
		daq when b"0000_0100_110", -- NMI / Implied
		inc when b"0000_1001_000", -- ORA / Immediate
		inc when b"0000_0101_000", -- ORA / Zero Page
		inc when b"0001_0101_000", -- ORA / Zero Page,X
		inc when b"0000_1101_000", -- ORA / Absolute
		inc when b"0000_1101_001", -- ORA / Absolute
		inc when b"0001_1101_000", -- ORA / Absolute,X
		inc when b"0001_1101_001", -- ORA / Absolute,X
		inc when b"0001_1001_000", -- ORA / Absolute,Y
		inc when b"0001_1001_001", -- ORA / Absolute,Y
		inc when b"0000_0001_000", -- ORA / (Indirect,X)
		inc when b"0001_0001_000", -- ORA / (Indirect),Y
		inc when b"0010_0110_000", -- ROL / Zero Page
		inc when b"0011_0110_000", -- ROL / Zero Page,X
		inc when b"0010_1110_000", -- ROL / Absolute
		inc when b"0010_1110_001", -- ROL / Absolute
		inc when b"0011_1110_000", -- ROL / Absolute,X
		inc when b"0011_1110_001", -- ROL / Absolute,X
		inc when b"0110_0110_000", -- ROR / Zero Page
		inc when b"0111_0110_000", -- ROR / Zero Page,X
		inc when b"0110_1110_000", -- ROR / Absolute
		inc when b"0110_1110_001", -- ROR / Absolute
		inc when b"0111_1110_000", -- ROR / Absolute,X
		inc when b"0111_1110_001", -- ROR / Absolute,X
		daq when b"0000_0010_011", -- RST / Implied
		daq when b"0100_0000_101", -- RTI / Implied
		daq when b"0110_0000_100", -- RTS / Implied
		inc when b"0110_0000_101", -- RTS / Implied
		inc when b"1110_1001_000", -- SBC / Immediate
		inc when b"1110_0101_000", -- SBC / Zero Page
		inc when b"1111_0101_000", -- SBC / Zero Page,X
		inc when b"1110_1101_000", -- SBC / Absolute
		inc when b"1110_1101_001", -- SBC / Absolute
		inc when b"1111_1101_000", -- SBC / Absolute,X
		inc when b"1111_1101_001", -- SBC / Absolute,X
		inc when b"1111_1001_000", -- SBC / Absolute,Y
		inc when b"1111_1001_001", -- SBC / Absolute,Y
		inc when b"1110_0001_000", -- SBC / (Indirect,X)
		inc when b"1111_0001_000", -- SBC / (Indirect),Y
		inc when b"1000_0101_000", -- STA / Zero Page
		inc when b"1001_0101_000", -- STA / Zero Page,X
		inc when b"1000_1101_000", -- STA / Absolute
		inc when b"1000_1101_001", -- STA / Absolute
		inc when b"1001_1101_000", -- STA / Absolute,X
		inc when b"1001_1101_001", -- STA / Absolute,X
		inc when b"1001_1001_000", -- STA / Absolute,Y
		inc when b"1001_1001_001", -- STA / Absolute,Y
		inc when b"1000_0001_000", -- STA / (Indirect,X)
		inc when b"1001_0001_000", -- STA / (Indirect),Y
		inc when b"1000_0110_000", -- STX / Zero Page
		inc when b"1001_0110_000", -- STX / Zero Page,Y
		inc when b"1000_1110_000", -- STX / Absolute
		inc when b"1000_1110_001", -- STX / Absolute
		inc when b"1000_0100_000", -- STY / Zero Page
		inc when b"1001_0100_000", -- STY / Zero Page,X
		inc when b"1000_1100_000", -- STY / Absolute
		inc when b"1000_1100_001", -- STY / Absolute
		nop when others;
		
	-- Input
	with s_addr select o_in_op <=
		ena when b"0111_1101_001", -- ADC / Absolute,X
		ena when b"0111_1101_010", -- ADC / Absolute,X
		ena when b"0111_1001_001", -- ADC / Absolute,Y
		ena when b"0111_1001_010", -- ADC / Absolute,Y
		ena when b"0110_0001_010", -- ADC / (Indirect,X)
		ena when b"0110_0001_011", -- ADC / (Indirect,X)
		ena when b"0111_0001_010", -- ADC / (Indirect),Y
		ena when b"0111_0001_011", -- ADC / (Indirect),Y
		ena when b"0011_1101_001", -- AND / Absolute,X
		ena when b"0011_1101_010", -- AND / Absolute,X
		ena when b"0011_1001_001", -- AND / Absolute,Y
		ena when b"0011_1001_010", -- AND / Absolute,Y
		ena when b"0010_0001_010", -- AND / (Indirect,X)
		ena when b"0010_0001_011", -- AND / (Indirect,X)
		ena when b"0011_0001_010", -- AND / (Indirect),Y
		ena when b"0011_0001_011", -- AND / (Indirect),Y
		alq when b"0000_0110_001", -- ASL / Zero Page
		alq when b"0001_0110_010", -- ASL / Zero Page,X
		ena when b"0000_1110_001", -- ASL / Absolute
		ena when b"0001_1110_001", -- ASL / Absolute,X
		ena when b"0001_1110_010", -- ASL / Absolute,X
		ald when b"0001_1110_011", -- ASL / Absolute,X
		fff when b"0000_0000_000", -- BRK / Implied
		ena when b"0000_0000_101", -- BRK / Implied
		ena when b"1101_1101_001", -- CMP / Absolute,X
		ena when b"1101_1101_010", -- CMP / Absolute,X
		ena when b"1101_1001_001", -- CMP / Absolute,Y
		ena when b"1101_1001_010", -- CMP / Absolute,Y
		ena when b"1100_0001_010", -- CMP / (Indirect,X)
		ena when b"1100_0001_011", -- CMP / (Indirect,X)
		ena when b"1101_0001_010", -- CMP / (Indirect),Y
		ena when b"1101_0001_011", -- CMP / (Indirect),Y
		ena when b"1100_0110_001", -- DEC / Zero Page
		ena when b"1101_0110_001", -- DEC / Zero Page,X
		alq when b"1101_0110_010", -- DEC / Zero Page,X
		ena when b"1100_1110_001", -- DEC / Absolute
		ena when b"1101_1110_001", -- DEC / Absolute,X
		ena when b"1101_1110_010", -- DEC / Absolute,X
		ald when b"1101_1110_011", -- DEC / Absolute,X
		ena when b"0101_1101_001", -- EOR / Absolute,X
		ena when b"0101_1101_010", -- EOR / Absolute,X
		ena when b"0101_1001_001", -- EOR / Absolute,Y
		ena when b"0101_1001_010", -- EOR / Absolute,Y
		ena when b"0100_0001_010", -- EOR / (Indirect,X)
		ena when b"0100_0001_011", -- EOR / (Indirect,X)
		ena when b"0101_0001_010", -- EOR / (Indirect),Y
		ena when b"0101_0001_011", -- EOR / (Indirect),Y
		ena when b"1110_0110_001", -- INC / Zero Page
		ena when b"1111_0110_001", -- INC / Zero Page,X
		alq when b"1111_0110_010", -- INC / Zero Page,X
		ena when b"1110_1110_001", -- INC / Absolute
		ena when b"1111_1110_001", -- INC / Absolute,X
		ena when b"1111_1110_010", -- INC / Absolute,X
		ald when b"1111_1110_011", -- INC / Absolute,X
		fff when b"0000_0011_000", -- INT / Implied
		ena when b"0000_0011_101", -- INT / Implied
		ena when b"0110_1100_010", -- JMP / Indirect
		ena when b"0110_1100_011", -- JMP / Indirect
		ena when b"0110_1100_100", -- JMP / Indirect
		ena when b"0010_0000_001", -- JSR / Absolute
		ena when b"1011_1101_001", -- LDA / Absolute,X
		ena when b"1011_1101_010", -- LDA / Absolute,X
		ena when b"1011_1001_001", -- LDA / Absolute,Y
		ena when b"1011_1001_010", -- LDA / Absolute,Y
		ena when b"1010_0001_010", -- LDA / (Indirect,X)
		ena when b"1010_0001_011", -- LDA / (Indirect,X)
		ena when b"1011_0001_010", -- LDA / (Indirect),Y
		ena when b"1011_0001_011", -- LDA / (Indirect),Y
		ena when b"1011_1110_001", -- LDX / Absolute,Y
		ena when b"1011_1110_010", -- LDX / Absolute,Y
		ena when b"1011_1100_001", -- LDY / Absolute,X
		ena when b"1011_1100_010", -- LDY / Absolute,X
		alq when b"0100_0110_001", -- LSR / Zero Page
		alq when b"0101_0110_010", -- LSR / Zero Page,X
		ena when b"0100_1110_001", -- LSR / Absolute
		ena when b"0101_1110_001", -- LSR / Absolute,X
		ena when b"0101_1110_010", -- LSR / Absolute,X
		ald when b"0101_1110_011", -- LSR / Absolute,X
		fff when b"0000_0100_000", -- NMI / Implied
		ena when b"0000_0100_101", -- NMI / Implied
		ena when b"0001_1101_001", -- ORA / Absolute,X
		ena when b"0001_1101_010", -- ORA / Absolute,X
		ena when b"0001_1001_001", -- ORA / Absolute,Y
		ena when b"0001_1001_010", -- ORA / Absolute,Y
		ena when b"0000_0001_010", -- ORA / (Indirect,X)
		ena when b"0000_0001_011", -- ORA / (Indirect,X)
		ena when b"0001_0001_010", -- ORA / (Indirect),Y
		ena when b"0001_0001_011", -- ORA / (Indirect),Y
		alq when b"0010_0110_001", -- ROL / Zero Page
		alq when b"0011_0110_010", -- ROL / Zero Page,X
		ena when b"0010_1110_001", -- ROL / Absolute
		ena when b"0011_1110_001", -- ROL / Absolute,X
		ena when b"0011_1110_010", -- ROL / Absolute,X
		ald when b"0011_1110_011", -- ROL / Absolute,X
		alq when b"0110_0110_001", -- ROR / Zero Page
		alq when b"0111_0110_010", -- ROR / Zero Page,X
		ena when b"0110_1110_001", -- ROR / Absolute
		ena when b"0111_1110_001", -- ROR / Absolute,X
		ena when b"0111_1110_010", -- ROR / Absolute,X
		ald when b"0111_1110_011", -- ROR / Absolute,X
		fff when b"0000_0010_000", -- RST / Implied
		ena when b"0000_0010_010", -- RST / Implied
		ena when b"0100_0000_100", -- RTI / Implied
		ena when b"0110_0000_011", -- RTS / Implied
		ena when b"1111_1101_001", -- SBC / Absolute,X
		ena when b"1111_1101_010", -- SBC / Absolute,X
		ena when b"1111_1001_001", -- SBC / Absolute,Y
		ena when b"1111_1001_010", -- SBC / Absolute,Y
		ena when b"1110_0001_010", -- SBC / (Indirect,X)
		ena when b"1110_0001_011", -- SBC / (Indirect,X)
		ena when b"1111_0001_010", -- SBC / (Indirect),Y
		ena when b"1111_0001_011", -- SBC / (Indirect),Y
		ena when b"1001_1101_001", -- STA / Absolute,X
		ena when b"1001_1101_010", -- STA / Absolute,X
		ena when b"1001_1001_001", -- STA / Absolute,Y
		ena when b"1001_1001_010", -- STA / Absolute,Y
		ena when b"1000_0001_010", -- STA / (Indirect,X)
		ena when b"1000_0001_011", -- STA / (Indirect,X)
		ena when b"1001_0001_010", -- STA / (Indirect),Y
		ena when b"1001_0001_011", -- STA / (Indirect),Y
		nop when others;
		
	-- Output
	with s_addr select o_out_op <=
		ena when b"0000_0110_010", -- ASL / Zero Page
		ena when b"0000_0110_011", -- ASL / Zero Page
		ena when b"0001_0110_011", -- ASL / Zero Page,X
		ena when b"0001_0110_100", -- ASL / Zero Page,X
		din when b"0000_1110_011", -- ASL / Absolute
		ena when b"0000_1110_100", -- ASL / Absolute
		din when b"0001_1110_100", -- ASL / Absolute,X
		ena when b"0001_1110_101", -- ASL / Absolute,X
		pch when b"0000_0000_001", -- BRK / Implied
		pcl when b"0000_0000_010", -- BRK / Implied
		flg when b"0000_0000_011", -- BRK / Implied
		ena when b"1100_0110_010", -- DEC / Zero Page
		ena when b"1100_0110_011", -- DEC / Zero Page
		ena when b"1101_0110_011", -- DEC / Zero Page,X
		ena when b"1101_0110_100", -- DEC / Zero Page,X
		din when b"1100_1110_011", -- DEC / Absolute
		ena when b"1100_1110_100", -- DEC / Absolute
		din when b"1101_1110_100", -- DEC / Absolute,X
		ena when b"1101_1110_101", -- DEC / Absolute,X
		ena when b"1110_0110_010", -- INC / Zero Page
		ena when b"1110_0110_011", -- INC / Zero Page
		ena when b"1111_0110_011", -- INC / Zero Page,X
		ena when b"1111_0110_100", -- INC / Zero Page,X
		din when b"1110_1110_011", -- INC / Absolute
		ena when b"1110_1110_100", -- INC / Absolute
		din when b"1111_1110_100", -- INC / Absolute,X
		ena when b"1111_1110_101", -- INC / Absolute,X
		pch when b"0000_0011_001", -- INT / Implied
		pcl when b"0000_0011_010", -- INT / Implied
		flg when b"0000_0011_011", -- INT / Implied
		pch when b"0010_0000_010", -- JSR / Absolute
		pcl when b"0010_0000_011", -- JSR / Absolute
		ena when b"0100_0110_010", -- LSR / Zero Page
		ena when b"0100_0110_011", -- LSR / Zero Page
		ena when b"0101_0110_011", -- LSR / Zero Page,X
		ena when b"0101_0110_100", -- LSR / Zero Page,X
		din when b"0100_1110_011", -- LSR / Absolute
		ena when b"0100_1110_100", -- LSR / Absolute
		din when b"0101_1110_100", -- LSR / Absolute,X
		ena when b"0101_1110_101", -- LSR / Absolute,X
		pch when b"0000_0100_001", -- NMI / Implied
		pcl when b"0000_0100_010", -- NMI / Implied
		flg when b"0000_0100_011", -- NMI / Implied
		arg when b"0100_1000_001", -- PHA / Implied
		flg when b"0000_1000_001", -- PHP / Implied
		ena when b"0010_0110_010", -- ROL / Zero Page
		ena when b"0010_0110_011", -- ROL / Zero Page
		ena when b"0011_0110_011", -- ROL / Zero Page,X
		ena when b"0011_0110_100", -- ROL / Zero Page,X
		din when b"0010_1110_011", -- ROL / Absolute
		ena when b"0010_1110_100", -- ROL / Absolute
		din when b"0011_1110_100", -- ROL / Absolute,X
		ena when b"0011_1110_101", -- ROL / Absolute,X
		ena when b"0110_0110_010", -- ROR / Zero Page
		ena when b"0110_0110_011", -- ROR / Zero Page
		ena when b"0111_0110_011", -- ROR / Zero Page,X
		ena when b"0111_0110_100", -- ROR / Zero Page,X
		din when b"0110_1110_011", -- ROR / Absolute
		ena when b"0110_1110_100", -- ROR / Absolute
		din when b"0111_1110_100", -- ROR / Absolute,X
		ena when b"0111_1110_101", -- ROR / Absolute,X
		arg when b"1000_0101_001", -- STA / Zero Page
		arg when b"1001_0101_010", -- STA / Zero Page,X
		arg when b"1000_1101_010", -- STA / Absolute
		arg when b"1001_1101_011", -- STA / Absolute,X
		arg when b"1001_1001_011", -- STA / Absolute,Y
		arg when b"1000_0001_100", -- STA / (Indirect,X)
		arg when b"1001_0001_100", -- STA / (Indirect),Y
		xrg when b"1000_0110_001", -- STX / Zero Page
		xrg when b"1001_0110_010", -- STX / Zero Page,Y
		xrg when b"1000_1110_010", -- STX / Absolute
		yrg when b"1000_0100_001", -- STY / Zero Page
		yrg when b"1001_0100_010", -- STY / Zero Page,X
		yrg when b"1000_1100_010", -- STY / Absolute
		nop when others;
		
	-- Flags
	with s_addr select o_flags_op <=
		nvzc when b"0110_1001_001", -- ADC / Immediate
		nvzc when b"0110_0101_010", -- ADC / Zero Page
		nvzc when b"0111_0101_011", -- ADC / Zero Page,X
		nvzc when b"0110_1101_011", -- ADC / Absolute
		nvzc when b"0111_1101_100", -- ADC / Absolute,X
		nvzc when b"0111_1001_100", -- ADC / Absolute,Y
		nvzc when b"0110_0001_101", -- ADC / (Indirect,X)
		nvzc when b"0111_0001_101", -- ADC / (Indirect),Y
		nz when b"0010_1001_001", -- AND / Immediate
		nz when b"0010_0101_010", -- AND / Zero Page
		nz when b"0011_0101_011", -- AND / Zero Page,X
		nz when b"0010_1101_011", -- AND / Absolute
		nz when b"0011_1101_100", -- AND / Absolute,X
		nz when b"0011_1001_100", -- AND / Absolute,Y
		nz when b"0010_0001_101", -- AND / (Indirect,X)
		nz when b"0011_0001_101", -- AND / (Indirect),Y
		nzc when b"0000_1010_001", -- ASL / Accumulator
		nzc when b"0000_0110_011", -- ASL / Zero Page
		nzc when b"0001_0110_100", -- ASL / Zero Page,X
		nzc when b"0000_1110_100", -- ASL / Absolute
		nzc when b"0001_1110_101", -- ASL / Absolute,X
		nzv when b"0010_0100_010", -- BIT / Zero Page
		nzv when b"0010_1100_011", -- BIT / Absolute
		sei when b"0000_0000_011", -- BRK / Implied
		clc when b"0001_1000_000", -- CLC / Implied
		cld when b"1101_1000_000", -- CLD / Implied
		cli when b"0101_1000_000", -- CLI / Implied
		clv when b"1011_1000_000", -- CLV / Implied
		nzc when b"1100_1001_001", -- CMP / Immediate
		nzc when b"1100_0101_010", -- CMP / Zero Page
		nzc when b"1101_0101_011", -- CMP / Zero Page,X
		nzc when b"1100_1101_011", -- CMP / Absolute
		nzc when b"1101_1101_100", -- CMP / Absolute,X
		nzc when b"1101_1001_100", -- CMP / Absolute,Y
		nzc when b"1100_0001_101", -- CMP / (Indirect,X)
		nzc when b"1101_0001_101", -- CMP / (Indirect),Y
		nzc when b"1110_0000_001", -- CPX / Immediate
		nzc when b"1110_0100_010", -- CPX / Zero Page
		nzc when b"1110_1100_011", -- CPX / Absolute
		nzc when b"1100_0000_001", -- CPY / Immediate
		nzc when b"1100_0100_010", -- CPY / Zero Page
		nzc when b"1100_1100_011", -- CPY / Absolute
		nz when b"1100_0110_011", -- DEC / Zero Page
		nz when b"1101_0110_100", -- DEC / Zero Page,X
		nz when b"1100_1110_100", -- DEC / Absolute
		nz when b"1101_1110_101", -- DEC / Absolute,X
		nz when b"1100_1010_001", -- DEX / Implied
		nz when b"1000_1000_001", -- DEY / Implied
		nz when b"0100_1001_001", -- EOR / Immediate
		nz when b"0100_0101_010", -- EOR / Zero Page
		nz when b"0101_0101_011", -- EOR / Zero Page,X
		nz when b"0100_1101_011", -- EOR / Absolute
		nz when b"0101_1101_100", -- EOR / Absolute,X
		nz when b"0101_1001_100", -- EOR / Absolute,Y
		nz when b"0100_0001_101", -- EOR / (Indirect,X)
		nz when b"0101_0001_101", -- EOR / (Indirect),Y
		nz when b"1110_0110_011", -- INC / Zero Page
		nz when b"1111_0110_100", -- INC / Zero Page,X
		nz when b"1110_1110_100", -- INC / Absolute
		nz when b"1111_1110_101", -- INC / Absolute,X
		sei when b"0000_0011_011", -- INT / Implied
		nz when b"1110_1000_001", -- INX / Implied
		nz when b"1100_1000_001", -- INY / Implied
		nz when b"1010_1001_001", -- LDA / Immediate
		nz when b"1010_0101_010", -- LDA / Zero Page
		nz when b"1011_0101_011", -- LDA / Zero Page,X
		nz when b"1010_1101_011", -- LDA / Absolute
		nz when b"1011_1101_100", -- LDA / Absolute,X
		nz when b"1011_1001_100", -- LDA / Absolute,Y
		nz when b"1010_0001_101", -- LDA / (Indirect,X)
		nz when b"1011_0001_101", -- LDA / (Indirect),Y
		nz when b"1010_0010_001", -- LDX / Immediate
		nz when b"1010_0110_010", -- LDX / Zero Page
		nz when b"1011_0110_011", -- LDX / Zero Page,Y
		nz when b"1010_1110_011", -- LDX / Absolute
		nz when b"1011_1110_100", -- LDX / Absolute,Y
		nz when b"1010_0000_001", -- LDY / Immediate
		nz when b"1010_0100_010", -- LDY / Zero Page
		nz when b"1011_0100_011", -- LDY / Zero Page,X
		nz when b"1010_1100_011", -- LDY / Absolute
		nz when b"1011_1100_100", -- LDY / Absolute,X
		nzc when b"0100_1010_001", -- LSR / Accumulator
		nzc when b"0100_0110_011", -- LSR / Zero Page
		nzc when b"0101_0110_100", -- LSR / Zero Page,X
		nzc when b"0100_1110_100", -- LSR / Absolute
		nzc when b"0101_1110_101", -- LSR / Absolute,X
		sei when b"0000_0100_011", -- NMI / Implied
		nz when b"0000_1001_001", -- ORA / Immediate
		nz when b"0000_0101_010", -- ORA / Zero Page
		nz when b"0001_0101_011", -- ORA / Zero Page,X
		nz when b"0000_1101_011", -- ORA / Absolute
		nz when b"0001_1101_100", -- ORA / Absolute,X
		nz when b"0001_1001_100", -- ORA / Absolute,Y
		nz when b"0000_0001_101", -- ORA / (Indirect,X)
		nz when b"0001_0001_101", -- ORA / (Indirect),Y
		nz when b"0110_1000_011", -- PLA / Implied
		din when b"0010_1000_011", -- PLP / Implied
		nzc when b"0010_1010_001", -- ROL / Accumulator
		nzc when b"0010_0110_011", -- ROL / Zero Page
		nzc when b"0011_0110_100", -- ROL / Zero Page,X
		nzc when b"0010_1110_100", -- ROL / Absolute
		nzc when b"0011_1110_101", -- ROL / Absolute,X
		nzc when b"0110_1010_001", -- ROR / Accumulator
		nzc when b"0110_0110_011", -- ROR / Zero Page
		nzc when b"0111_0110_100", -- ROR / Zero Page,X
		nzc when b"0110_1110_100", -- ROR / Absolute
		nzc when b"0111_1110_101", -- ROR / Absolute,X
		din when b"0100_0000_011", -- RTI / Implied
		nvzc when b"1110_1001_001", -- SBC / Immediate
		nvzc when b"1110_0101_010", -- SBC / Zero Page
		nvzc when b"1111_0101_011", -- SBC / Zero Page,X
		nvzc when b"1110_1101_011", -- SBC / Absolute
		nvzc when b"1111_1101_100", -- SBC / Absolute,X
		nvzc when b"1111_1001_100", -- SBC / Absolute,Y
		nvzc when b"1110_0001_101", -- SBC / (Indirect,X)
		nvzc when b"1111_0001_101", -- SBC / (Indirect),Y
		stc when b"0011_1000_000", -- SEC / Implied
		sed when b"1111_1000_000", -- SED / Implied
		sei when b"0111_1000_000", -- SEI / Implied
		nz when b"1010_1010_001", -- TAX / Implied
		nz when b"1010_1000_001", -- TAY / Implied
		nz when b"1011_1010_001", -- TSX / Implied
		nz when b"1000_1010_001", -- TXA / Implied
		nz when b"1001_1000_001", -- TYA / Implied
		nop when others;
		
	-- ALU Operation
	with s_addr select o_alu_op <=
		adc when b"0110_1001_001", -- ADC / Immediate
		adc when b"0110_0101_010", -- ADC / Zero Page
		add when b"0111_0101_010", -- ADC / Zero Page,X
		adc when b"0111_0101_011", -- ADC / Zero Page,X
		adc when b"0110_1101_011", -- ADC / Absolute
		add when b"0111_1101_010", -- ADC / Absolute,X
		add when b"0111_1101_011", -- ADC / Absolute,X
		adc when b"0111_1101_100", -- ADC / Absolute,X
		add when b"0111_1001_010", -- ADC / Absolute,Y
		add when b"0111_1001_011", -- ADC / Absolute,Y
		adc when b"0111_1001_100", -- ADC / Absolute,Y
		add when b"0110_0001_010", -- ADC / (Indirect,X)
		add when b"0110_0001_011", -- ADC / (Indirect,X)
		adc when b"0110_0001_101", -- ADC / (Indirect,X)
		add when b"0111_0001_010", -- ADC / (Indirect),Y
		add when b"0111_0001_011", -- ADC / (Indirect),Y
		add when b"0111_0001_100", -- ADC / (Indirect),Y
		adc when b"0111_0001_101", -- ADC / (Indirect),Y
		ada when b"0010_1001_001", -- AND / Immediate
		ada when b"0010_0101_010", -- AND / Zero Page
		add when b"0011_0101_010", -- AND / Zero Page,X
		ada when b"0011_0101_011", -- AND / Zero Page,X
		ada when b"0010_1101_011", -- AND / Absolute
		add when b"0011_1101_010", -- AND / Absolute,X
		add when b"0011_1101_011", -- AND / Absolute,X
		ada when b"0011_1101_100", -- AND / Absolute,X
		add when b"0011_1001_010", -- AND / Absolute,Y
		add when b"0011_1001_011", -- AND / Absolute,Y
		ada when b"0011_1001_100", -- AND / Absolute,Y
		add when b"0010_0001_010", -- AND / (Indirect,X)
		add when b"0010_0001_011", -- AND / (Indirect,X)
		ada when b"0010_0001_101", -- AND / (Indirect,X)
		add when b"0011_0001_010", -- AND / (Indirect),Y
		add when b"0011_0001_011", -- AND / (Indirect),Y
		add when b"0011_0001_100", -- AND / (Indirect),Y
		ada when b"0011_0001_101", -- AND / (Indirect),Y
		asl when b"0000_1010_001", -- ASL / Accumulator
		asl when b"0000_0110_011", -- ASL / Zero Page
		add when b"0001_0110_010", -- ASL / Zero Page,X
		asl when b"0001_0110_100", -- ASL / Zero Page,X
		asl when b"0000_1110_100", -- ASL / Absolute
		add when b"0001_1110_010", -- ASL / Absolute,X
		add when b"0001_1110_011", -- ASL / Absolute,X
		asl when b"0001_1110_101", -- ASL / Absolute,X
		add when b"1001_0000_001", -- BCC / Relative
		add when b"1001_0000_010", -- BCC / Relative
		add when b"1011_0000_001", -- BCS / Relative
		add when b"1011_0000_010", -- BCS / Relative
		add when b"1111_0000_001", -- BEQ / Relative
		add when b"1111_0000_010", -- BEQ / Relative
		ada when b"0010_0100_010", -- BIT / Zero Page
		ada when b"0010_1100_011", -- BIT / Absolute
		add when b"0011_0000_001", -- BMI / Relative
		add when b"0011_0000_010", -- BMI / Relative
		add when b"1101_0000_001", -- BNE / Relative
		add when b"1101_0000_010", -- BNE / Relative
		add when b"0001_0000_001", -- BPL / Relative
		add when b"0001_0000_010", -- BPL / Relative
		sub when b"0000_0000_001", -- BRK / Implied
		sub when b"0000_0000_010", -- BRK / Implied
		sub when b"0000_0000_011", -- BRK / Implied
		add when b"0000_0000_101", -- BRK / Implied
		add when b"0101_0000_001", -- BVC / Relative
		add when b"0101_0000_010", -- BVC / Relative
		add when b"0111_0000_001", -- BVS / Relative
		add when b"0111_0000_010", -- BVS / Relative
		sub when b"1100_1001_001", -- CMP / Immediate
		sub when b"1100_0101_010", -- CMP / Zero Page
		add when b"1101_0101_010", -- CMP / Zero Page,X
		sub when b"1101_0101_011", -- CMP / Zero Page,X
		sub when b"1100_1101_011", -- CMP / Absolute
		add when b"1101_1101_010", -- CMP / Absolute,X
		add when b"1101_1101_011", -- CMP / Absolute,X
		sub when b"1101_1101_100", -- CMP / Absolute,X
		add when b"1101_1001_010", -- CMP / Absolute,Y
		add when b"1101_1001_011", -- CMP / Absolute,Y
		sub when b"1101_1001_100", -- CMP / Absolute,Y
		add when b"1100_0001_010", -- CMP / (Indirect,X)
		add when b"1100_0001_011", -- CMP / (Indirect,X)
		sub when b"1100_0001_101", -- CMP / (Indirect,X)
		add when b"1101_0001_010", -- CMP / (Indirect),Y
		add when b"1101_0001_011", -- CMP / (Indirect),Y
		add when b"1101_0001_100", -- CMP / (Indirect),Y
		sub when b"1101_0001_101", -- CMP / (Indirect),Y
		sub when b"1110_0000_001", -- CPX / Immediate
		sub when b"1110_0100_010", -- CPX / Zero Page
		sub when b"1110_1100_011", -- CPX / Absolute
		sub when b"1100_0000_001", -- CPY / Immediate
		sub when b"1100_0100_010", -- CPY / Zero Page
		sub when b"1100_1100_011", -- CPY / Absolute
		sub when b"1100_0110_011", -- DEC / Zero Page
		add when b"1101_0110_010", -- DEC / Zero Page,X
		sub when b"1101_0110_100", -- DEC / Zero Page,X
		sub when b"1100_1110_100", -- DEC / Absolute
		add when b"1101_1110_010", -- DEC / Absolute,X
		add when b"1101_1110_011", -- DEC / Absolute,X
		sub when b"1101_1110_101", -- DEC / Absolute,X
		sub when b"1100_1010_001", -- DEX / Implied
		sub when b"1000_1000_001", -- DEY / Implied
		eor when b"0100_1001_001", -- EOR / Immediate
		eor when b"0100_0101_010", -- EOR / Zero Page
		add when b"0101_0101_010", -- EOR / Zero Page,X
		eor when b"0101_0101_011", -- EOR / Zero Page,X
		eor when b"0100_1101_011", -- EOR / Absolute
		add when b"0101_1101_010", -- EOR / Absolute,X
		add when b"0101_1101_011", -- EOR / Absolute,X
		eor when b"0101_1101_100", -- EOR / Absolute,X
		add when b"0101_1001_010", -- EOR / Absolute,Y
		add when b"0101_1001_011", -- EOR / Absolute,Y
		eor when b"0101_1001_100", -- EOR / Absolute,Y
		add when b"0100_0001_010", -- EOR / (Indirect,X)
		add when b"0100_0001_011", -- EOR / (Indirect,X)
		eor when b"0100_0001_101", -- EOR / (Indirect,X)
		add when b"0101_0001_010", -- EOR / (Indirect),Y
		add when b"0101_0001_011", -- EOR / (Indirect),Y
		add when b"0101_0001_100", -- EOR / (Indirect),Y
		eor when b"0101_0001_101", -- EOR / (Indirect),Y
		add when b"1110_0110_011", -- INC / Zero Page
		add when b"1111_0110_010", -- INC / Zero Page,X
		add when b"1111_0110_100", -- INC / Zero Page,X
		add when b"1110_1110_100", -- INC / Absolute
		add when b"1111_1110_010", -- INC / Absolute,X
		add when b"1111_1110_011", -- INC / Absolute,X
		add when b"1111_1110_101", -- INC / Absolute,X
		sub when b"0000_0011_001", -- INT / Implied
		sub when b"0000_0011_010", -- INT / Implied
		sub when b"0000_0011_011", -- INT / Implied
		add when b"0000_0011_101", -- INT / Implied
		add when b"1110_1000_001", -- INX / Implied
		add when b"1100_1000_001", -- INY / Implied
		add when b"0110_1100_011", -- JMP / Indirect
		sub when b"0010_0000_011", -- JSR / Absolute
		sub when b"0010_0000_100", -- JSR / Absolute
		add when b"1011_0101_010", -- LDA / Zero Page,X
		add when b"1011_1101_010", -- LDA / Absolute,X
		add when b"1011_1101_011", -- LDA / Absolute,X
		add when b"1011_1001_010", -- LDA / Absolute,Y
		add when b"1011_1001_011", -- LDA / Absolute,Y
		add when b"1010_0001_010", -- LDA / (Indirect,X)
		add when b"1010_0001_011", -- LDA / (Indirect,X)
		add when b"1011_0001_010", -- LDA / (Indirect),Y
		add when b"1011_0001_011", -- LDA / (Indirect),Y
		add when b"1011_0001_100", -- LDA / (Indirect),Y
		add when b"1011_0110_010", -- LDX / Zero Page,Y
		add when b"1011_1110_010", -- LDX / Absolute,Y
		add when b"1011_1110_011", -- LDX / Absolute,Y
		add when b"1011_0100_010", -- LDY / Zero Page,X
		add when b"1011_1100_010", -- LDY / Absolute,X
		add when b"1011_1100_011", -- LDY / Absolute,X
		lsr when b"0100_1010_001", -- LSR / Accumulator
		lsr when b"0100_0110_011", -- LSR / Zero Page
		add when b"0101_0110_010", -- LSR / Zero Page,X
		lsr when b"0101_0110_100", -- LSR / Zero Page,X
		lsr when b"0100_1110_100", -- LSR / Absolute
		add when b"0101_1110_010", -- LSR / Absolute,X
		add when b"0101_1110_011", -- LSR / Absolute,X
		lsr when b"0101_1110_101", -- LSR / Absolute,X
		sub when b"0000_0100_001", -- NMI / Implied
		sub when b"0000_0100_010", -- NMI / Implied
		sub when b"0000_0100_011", -- NMI / Implied
		add when b"0000_0100_101", -- NMI / Implied
		ora when b"0000_1001_001", -- ORA / Immediate
		ora when b"0000_0101_010", -- ORA / Zero Page
		add when b"0001_0101_010", -- ORA / Zero Page,X
		ora when b"0001_0101_011", -- ORA / Zero Page,X
		ora when b"0000_1101_011", -- ORA / Absolute
		add when b"0001_1101_010", -- ORA / Absolute,X
		add when b"0001_1101_011", -- ORA / Absolute,X
		ora when b"0001_1101_100", -- ORA / Absolute,X
		add when b"0001_1001_010", -- ORA / Absolute,Y
		add when b"0001_1001_011", -- ORA / Absolute,Y
		ora when b"0001_1001_100", -- ORA / Absolute,Y
		add when b"0000_0001_010", -- ORA / (Indirect,X)
		add when b"0000_0001_011", -- ORA / (Indirect,X)
		ora when b"0000_0001_101", -- ORA / (Indirect,X)
		add when b"0001_0001_010", -- ORA / (Indirect),Y
		add when b"0001_0001_011", -- ORA / (Indirect),Y
		add when b"0001_0001_100", -- ORA / (Indirect),Y
		ora when b"0001_0001_101", -- ORA / (Indirect),Y
		sub when b"0100_1000_010", -- PHA / Implied
		sub when b"0000_1000_010", -- PHP / Implied
		add when b"0110_1000_010", -- PLA / Implied
		add when b"0010_1000_010", -- PLP / Implied
		add when b"0000_0010_010", -- RST / Implied
		add when b"0100_0000_010", -- RTI / Implied
		add when b"0100_0000_011", -- RTI / Implied
		add when b"0100_0000_100", -- RTI / Implied
		add when b"0110_0000_010", -- RTS / Implied
		add when b"0110_0000_011", -- RTS / Implied
		rla when b"0010_1010_001", -- ROL / Accumulator
		rla when b"0010_0110_011", -- ROL / Zero Page
		add when b"0011_0110_010", -- ROL / Zero Page,X
		rla when b"0011_0110_100", -- ROL / Zero Page,X
		rla when b"0010_1110_100", -- ROL / Absolute
		add when b"0011_1110_010", -- ROL / Absolute,X
		add when b"0011_1110_011", -- ROL / Absolute,X
		rla when b"0011_1110_101", -- ROL / Absolute,X
		rra when b"0110_1010_001", -- ROR / Accumulator
		rra when b"0110_0110_011", -- ROR / Zero Page
		add when b"0111_0110_010", -- ROR / Zero Page,X
		rra when b"0111_0110_100", -- ROR / Zero Page,X
		rra when b"0110_1110_100", -- ROR / Absolute
		add when b"0111_1110_010", -- ROR / Absolute,X
		add when b"0111_1110_011", -- ROR / Absolute,X
		rra when b"0111_1110_101", -- ROR / Absolute,X
		sbc when b"1110_1001_001", -- SBC / Immediate
		sbc when b"1110_0101_010", -- SBC / Zero Page
		add when b"1111_0101_010", -- SBC / Zero Page,X
		sbc when b"1111_0101_011", -- SBC / Zero Page,X
		sbc when b"1110_1101_011", -- SBC / Absolute
		add when b"1111_1101_010", -- SBC / Absolute,X
		add when b"1111_1101_011", -- SBC / Absolute,X
		sbc when b"1111_1101_100", -- SBC / Absolute,X
		add when b"1111_1001_010", -- SBC / Absolute,Y
		add when b"1111_1001_011", -- SBC / Absolute,Y
		sbc when b"1111_1001_100", -- SBC / Absolute,Y
		add when b"1110_0001_010", -- SBC / (Indirect,X)
		add when b"1110_0001_011", -- SBC / (Indirect,X)
		sbc when b"1110_0001_101", -- SBC / (Indirect,X)
		add when b"1111_0001_010", -- SBC / (Indirect),Y
		add when b"1111_0001_011", -- SBC / (Indirect),Y
		add when b"1111_0001_100", -- SBC / (Indirect),Y
		sbc when b"1111_0001_101", -- SBC / (Indirect),Y
		add when b"1000_0101_010", -- STA / Zero Page
		add when b"1001_0101_010", -- STA / Zero Page,X
		add when b"1001_1101_010", -- STA / Absolute,X
		add when b"1001_1101_011", -- STA / Absolute,X
		add when b"1001_1001_010", -- STA / Absolute,Y
		add when b"1001_1001_011", -- STA / Absolute,Y
		add when b"1000_0001_010", -- STA / (Indirect,X)
		add when b"1000_0001_011", -- STA / (Indirect,X)
		add when b"1001_0001_010", -- STA / (Indirect),Y
		add when b"1001_0001_011", -- STA / (Indirect),Y
		add when b"1001_0001_100", -- STA / (Indirect),Y
		add when b"1000_0110_010", -- STX / Zero Page
		add when b"1001_0110_010", -- STX / Zero Page,Y
		add when b"1000_0100_010", -- STY / Zero Page
		add when b"1001_0100_010", -- STY / Zero Page,X
		psa when others;
		
	-- ALU Input A
	with s_addr select o_alu_a_op <=
		arg when b"0110_1001_001", -- ADC / Immediate
		arg when b"0110_0101_010", -- ADC / Zero Page
		xrg when b"0111_0101_010", -- ADC / Zero Page,X
		arg when b"0111_0101_011", -- ADC / Zero Page,X
		arg when b"0110_1101_011", -- ADC / Absolute
		xrg when b"0111_1101_010", -- ADC / Absolute,X
		val when b"0111_1101_011", -- ADC / Absolute,X
		arg when b"0111_1101_100", -- ADC / Absolute,X
		yrg when b"0111_1001_010", -- ADC / Absolute,Y
		val when b"0111_1001_011", -- ADC / Absolute,Y
		arg when b"0111_1001_100", -- ADC / Absolute,Y
		xrg when b"0110_0001_010", -- ADC / (Indirect,X)
		alq when b"0110_0001_011", -- ADC / (Indirect,X)
		val when b"0110_0001_100", -- ADC / (Indirect,X)
		arg when b"0110_0001_101", -- ADC / (Indirect,X)
		alq when b"0111_0001_010", -- ADC / (Indirect),Y
		yrg when b"0111_0001_011", -- ADC / (Indirect),Y
		val when b"0111_0001_100", -- ADC / (Indirect),Y
		arg when b"0111_0001_101", -- ADC / (Indirect),Y
		arg when b"0010_1001_001", -- AND / Immediate
		arg when b"0010_0101_010", -- AND / Zero Page
		xrg when b"0011_0101_010", -- AND / Zero Page,X
		arg when b"0011_0101_011", -- AND / Zero Page,X
		arg when b"0010_1101_011", -- AND / Absolute
		xrg when b"0011_1101_010", -- AND / Absolute,X
		val when b"0011_1101_011", -- AND / Absolute,X
		arg when b"0011_1101_100", -- AND / Absolute,X
		yrg when b"0011_1001_010", -- AND / Absolute,Y
		val when b"0011_1001_011", -- AND / Absolute,Y
		arg when b"0011_1001_100", -- AND / Absolute,Y
		xrg when b"0010_0001_010", -- AND / (Indirect,X)
		alq when b"0010_0001_011", -- AND / (Indirect,X)
		val when b"0010_0001_100", -- AND / (Indirect,X)
		arg when b"0010_0001_101", -- AND / (Indirect,X)
		alq when b"0011_0001_010", -- AND / (Indirect),Y
		yrg when b"0011_0001_011", -- AND / (Indirect),Y
		val when b"0011_0001_100", -- AND / (Indirect),Y
		arg when b"0011_0001_101", -- AND / (Indirect),Y
		arg when b"0000_1010_001", -- ASL / Accumulator
		xrg when b"0001_0110_010", -- ASL / Zero Page,X
		alq when b"0000_1110_011", -- ASL / Absolute
		xrg when b"0001_1110_010", -- ASL / Absolute,X
		val when b"0001_1110_011", -- ASL / Absolute,X
		alq when b"0001_1110_100", -- ASL / Absolute,X
		pcl when b"1001_0000_001", -- BCC / Relative
		pch when b"1001_0000_010", -- BCC / Relative
		pcl when b"1011_0000_001", -- BCS / Relative
		pch when b"1011_0000_010", -- BCS / Relative
		pcl when b"1111_0000_001", -- BEQ / Relative
		pch when b"1111_0000_010", -- BEQ / Relative
		arg when b"0010_0100_010", -- BIT / Zero Page
		arg when b"0010_1100_011", -- BIT / Absolute
		pcl when b"0011_0000_001", -- BMI / Relative
		pch when b"0011_0000_010", -- BMI / Relative
		pcl when b"1101_0000_001", -- BNE / Relative
		pch when b"1101_0000_010", -- BNE / Relative
		pcl when b"0001_0000_001", -- BPL / Relative
		pch when b"0001_0000_010", -- BPL / Relative
		srg when b"0000_0000_000", -- BRK / Implied
		alq when b"0000_0000_001", -- BRK / Implied
		alq when b"0000_0000_010", -- BRK / Implied
		alq when b"0000_0000_011", -- BRK / Implied
		brk when b"0000_0000_100", -- BRK / Implied
		alq when b"0000_0000_101", -- BRK / Implied
		val when b"0000_0000_110", -- BRK / Implied
		pcl when b"0101_0000_001", -- BVC / Relative
		pch when b"0101_0000_010", -- BVC / Relative
		pcl when b"0111_0000_001", -- BVS / Relative
		pch when b"0111_0000_010", -- BVS / Relative
		arg when b"1100_1001_001", -- CMP / Immediate
		arg when b"1100_0101_010", -- CMP / Zero Page
		xrg when b"1101_0101_010", -- CMP / Zero Page,X
		arg when b"1101_0101_011", -- CMP / Zero Page,X
		arg when b"1100_1101_011", -- CMP / Absolute
		xrg when b"1101_1101_010", -- CMP / Absolute,X
		val when b"1101_1101_011", -- CMP / Absolute,X
		arg when b"1101_1101_100", -- CMP / Absolute,X
		yrg when b"1101_1001_010", -- CMP / Absolute,Y
		val when b"1101_1001_011", -- CMP / Absolute,Y
		arg when b"1101_1001_100", -- CMP / Absolute,Y
		xrg when b"1100_0001_010", -- CMP / (Indirect,X)
		alq when b"1100_0001_011", -- CMP / (Indirect,X)
		val when b"1100_0001_100", -- CMP / (Indirect,X)
		arg when b"1100_0001_101", -- CMP / (Indirect,X)
		alq when b"1101_0001_010", -- CMP / (Indirect),Y
		yrg when b"1101_0001_011", -- CMP / (Indirect),Y
		val when b"1101_0001_100", -- CMP / (Indirect),Y
		arg when b"1101_0001_101", -- CMP / (Indirect),Y
		xrg when b"1110_0000_001", -- CPX / Immediate
		xrg when b"1110_0100_010", -- CPX / Zero Page
		xrg when b"1110_1100_011", -- CPX / Absolute
		yrg when b"1100_0000_001", -- CPY / Immediate
		yrg when b"1100_0100_010", -- CPY / Zero Page
		yrg when b"1100_1100_011", -- CPY / Absolute
		xrg when b"1101_0110_010", -- DEC / Zero Page,X
		alq when b"1100_1110_011", -- DEC / Absolute
		xrg when b"1101_1110_010", -- DEC / Absolute,X
		val when b"1101_1110_011", -- DEC / Absolute,X
		alq when b"1101_1110_100", -- DEC / Absolute,X
		xrg when b"1100_1010_001", -- DEX / Implied
		yrg when b"1000_1000_001", -- DEY / Implied
		arg when b"0100_1001_001", -- EOR / Immediate
		arg when b"0100_0101_010", -- EOR / Zero Page
		xrg when b"0101_0101_010", -- EOR / Zero Page,X
		arg when b"0101_0101_011", -- EOR / Zero Page,X
		arg when b"0100_1101_011", -- EOR / Absolute
		xrg when b"0101_1101_010", -- EOR / Absolute,X
		val when b"0101_1101_011", -- EOR / Absolute,X
		arg when b"0101_1101_100", -- EOR / Absolute,X
		yrg when b"0101_1001_010", -- EOR / Absolute,Y
		val when b"0101_1001_011", -- EOR / Absolute,Y
		arg when b"0101_1001_100", -- EOR / Absolute,Y
		xrg when b"0100_0001_010", -- EOR / (Indirect,X)
		alq when b"0100_0001_011", -- EOR / (Indirect,X)
		val when b"0100_0001_100", -- EOR / (Indirect,X)
		arg when b"0100_0001_101", -- EOR / (Indirect,X)
		alq when b"0101_0001_010", -- EOR / (Indirect),Y
		yrg when b"0101_0001_011", -- EOR / (Indirect),Y
		val when b"0101_0001_100", -- EOR / (Indirect),Y
		arg when b"0101_0001_101", -- EOR / (Indirect),Y
		xrg when b"1111_0110_010", -- INC / Zero Page,X
		alq when b"1110_1110_011", -- INC / Absolute
		xrg when b"1111_1110_010", -- INC / Absolute,X
		val when b"1111_1110_011", -- INC / Absolute,X
		alq when b"1111_1110_100", -- INC / Absolute,X
		srg when b"0000_0011_000", -- INT / Implied
		alq when b"0000_0011_001", -- INT / Implied
		alq when b"0000_0011_010", -- INT / Implied
		alq when b"0000_0011_011", -- INT / Implied
		brk when b"0000_0011_100", -- INT / Implied
		alq when b"0000_0011_101", -- INT / Implied
		val when b"0000_0011_110", -- INT / Implied
		xrg when b"1110_1000_001", -- INX / Implied
		yrg when b"1100_1000_001", -- INY / Implied
		alq when b"0100_1100_010", -- JMP / Absolute
		alq when b"0110_1100_010", -- JMP / Indirect
		alq when b"0110_1100_011", -- JMP / Indirect
		val when b"0110_1100_100", -- JMP / Indirect
		srg when b"0010_0000_001", -- JSR / Absolute
		alq when b"0010_0000_010", -- JSR / Absolute
		alq when b"0010_0000_011", -- JSR / Absolute
		alq when b"0010_0000_100", -- JSR / Absolute
		val when b"0010_0000_101", -- JSR / Absolute
		xrg when b"1011_0101_010", -- LDA / Zero Page,X
		xrg when b"1011_1101_010", -- LDA / Absolute,X
		val when b"1011_1101_011", -- LDA / Absolute,X
		yrg when b"1011_1001_010", -- LDA / Absolute,Y
		val when b"1011_1001_011", -- LDA / Absolute,Y
		xrg when b"1010_0001_010", -- LDA / (Indirect,X)
		alq when b"1010_0001_011", -- LDA / (Indirect,X)
		val when b"1010_0001_100", -- LDA / (Indirect,X)
		alq when b"1011_0001_010", -- LDA / (Indirect),Y
		yrg when b"1011_0001_011", -- LDA / (Indirect),Y
		val when b"1011_0001_100", -- LDA / (Indirect),Y
		yrg when b"1011_0110_010", -- LDX / Zero Page,Y
		yrg when b"1011_1110_010", -- LDX / Absolute,Y
		val when b"1011_1110_011", -- LDX / Absolute,Y
		xrg when b"1011_0100_010", -- LDY / Zero Page,X
		xrg when b"1011_1100_010", -- LDY / Absolute,X
		val when b"1011_1100_011", -- LDY / Absolute,X
		arg when b"0100_1010_001", -- LSR / Accumulator
		xrg when b"0101_0110_010", -- LSR / Zero Page,X
		alq when b"0100_1110_011", -- LSR / Absolute
		xrg when b"0101_1110_010", -- LSR / Absolute,X
		val when b"0101_1110_011", -- LSR / Absolute,X
		alq when b"0101_1110_100", -- LSR / Absolute,X
		srg when b"0000_0100_000", -- NMI / Implied
		alq when b"0000_0100_001", -- NMI / Implied
		alq when b"0000_0100_010", -- NMI / Implied
		alq when b"0000_0100_011", -- NMI / Implied
		brk when b"0000_0100_100", -- NMI / Implied
		alq when b"0000_0100_101", -- NMI / Implied
		val when b"0000_0100_110", -- NMI / Implied
		arg when b"0000_1001_001", -- ORA / Immediate
		arg when b"0000_0101_010", -- ORA / Zero Page
		xrg when b"0001_0101_010", -- ORA / Zero Page,X
		arg when b"0001_0101_011", -- ORA / Zero Page,X
		arg when b"0000_1101_011", -- ORA / Absolute
		xrg when b"0001_1101_010", -- ORA / Absolute,X
		val when b"0001_1101_011", -- ORA / Absolute,X
		arg when b"0001_1101_100", -- ORA / Absolute,X
		yrg when b"0001_1001_010", -- ORA / Absolute,Y
		val when b"0001_1001_011", -- ORA / Absolute,Y
		arg when b"0001_1001_100", -- ORA / Absolute,Y
		xrg when b"0000_0001_010", -- ORA / (Indirect,X)
		alq when b"0000_0001_011", -- ORA / (Indirect,X)
		val when b"0000_0001_100", -- ORA / (Indirect,X)
		arg when b"0000_0001_101", -- ORA / (Indirect,X)
		alq when b"0001_0001_010", -- ORA / (Indirect),Y
		yrg when b"0001_0001_011", -- ORA / (Indirect),Y
		val when b"0001_0001_100", -- ORA / (Indirect),Y
		arg when b"0001_0001_101", -- ORA / (Indirect),Y
		srg when b"0100_1000_001", -- PHA / Implied
		alq when b"0100_1000_010", -- PHA / Implied
		srg when b"0000_1000_001", -- PHP / Implied
		alq when b"0000_1000_010", -- PHP / Implied
		srg when b"0110_1000_001", -- PLA / Implied
		alq when b"0110_1000_010", -- PLA / Implied
		srg when b"0010_1000_001", -- PLP / Implied
		alq when b"0010_1000_010", -- PLP / Implied
		arg when b"0010_1010_001", -- ROL / Accumulator
		xrg when b"0011_0110_010", -- ROL / Zero Page,X
		alq when b"0010_1110_011", -- ROL / Absolute
		xrg when b"0011_1110_010", -- ROL / Absolute,X
		val when b"0011_1110_011", -- ROL / Absolute,X
		alq when b"0011_1110_100", -- ROL / Absolute,X
		arg when b"0110_1010_001", -- ROR / Accumulator
		xrg when b"0111_0110_010", -- ROR / Zero Page,X
		alq when b"0110_1110_011", -- ROR / Absolute
		xrg when b"0111_1110_010", -- ROR / Absolute,X
		val when b"0111_1110_011", -- ROR / Absolute,X
		alq when b"0111_1110_100", -- ROR / Absolute,X
		brk when b"0000_0010_001", -- RST / Implied
		alq when b"0000_0010_010", -- RST / Implied
		val when b"0000_0010_011", -- RST / Implied
		srg when b"0100_0000_001", -- RTI / Implied
		alq when b"0100_0000_010", -- RTI / Implied
		alq when b"0100_0000_011", -- RTI / Implied
		alq when b"0100_0000_100", -- RTI / Implied
		val when b"0100_0000_101", -- RTI / Implied
		srg when b"0110_0000_001", -- RTS / Implied
		alq when b"0110_0000_010", -- RTS / Implied
		alq when b"0110_0000_011", -- RTS / Implied
		val when b"0110_0000_100", -- RTS / Implied
		arg when b"1110_1001_001", -- SBC / Immediate
		arg when b"1110_0101_010", -- SBC / Zero Page
		xrg when b"1111_0101_010", -- SBC / Zero Page,X
		arg when b"1111_0101_011", -- SBC / Zero Page,X
		arg when b"1110_1101_011", -- SBC / Absolute
		xrg when b"1111_1101_010", -- SBC / Absolute,X
		val when b"1111_1101_011", -- SBC / Absolute,X
		arg when b"1111_1101_100", -- SBC / Absolute,X
		yrg when b"1111_1001_010", -- SBC / Absolute,Y
		val when b"1111_1001_011", -- SBC / Absolute,Y
		arg when b"1111_1001_100", -- SBC / Absolute,Y
		xrg when b"1110_0001_010", -- SBC / (Indirect,X)
		alq when b"1110_0001_011", -- SBC / (Indirect,X)
		val when b"1110_0001_100", -- SBC / (Indirect,X)
		arg when b"1110_0001_101", -- SBC / (Indirect,X)
		alq when b"1111_0001_010", -- SBC / (Indirect),Y
		yrg when b"1111_0001_011", -- SBC / (Indirect),Y
		val when b"1111_0001_100", -- SBC / (Indirect),Y
		arg when b"1111_0001_101", -- SBC / (Indirect),Y
		arg when b"1000_0101_010", -- STA / Zero Page
		xrg when b"1001_0101_010", -- STA / Zero Page,X
		arg when b"1001_0101_011", -- STA / Zero Page,X
		arg when b"1000_1101_011", -- STA / Absolute
		xrg when b"1001_1101_010", -- STA / Absolute,X
		val when b"1001_1101_011", -- STA / Absolute,X
		arg when b"1001_1101_100", -- STA / Absolute,X
		yrg when b"1001_1001_010", -- STA / Absolute,Y
		val when b"1001_1001_011", -- STA / Absolute,Y
		arg when b"1001_1001_100", -- STA / Absolute,Y
		xrg when b"1000_0001_010", -- STA / (Indirect,X)
		alq when b"1000_0001_011", -- STA / (Indirect,X)
		val when b"1000_0001_100", -- STA / (Indirect,X)
		arg when b"1000_0001_101", -- STA / (Indirect,X)
		alq when b"1001_0001_010", -- STA / (Indirect),Y
		yrg when b"1001_0001_011", -- STA / (Indirect),Y
		val when b"1001_0001_100", -- STA / (Indirect),Y
		arg when b"1001_0001_101", -- STA / (Indirect),Y
		xrg when b"1000_0110_010", -- STX / Zero Page
		yrg when b"1001_0110_010", -- STX / Zero Page,Y
		xrg when b"1001_0110_011", -- STX / Zero Page,Y
		xrg when b"1000_1110_011", -- STX / Absolute
		yrg when b"1000_0100_010", -- STY / Zero Page
		xrg when b"1001_0100_010", -- STY / Zero Page,X
		yrg when b"1001_0100_011", -- STY / Zero Page,X
		yrg when b"1000_1100_011", -- STY / Absolute
		arg when b"1010_1010_001", -- TAX / Implied
		arg when b"1010_1000_001", -- TAY / Implied
		srg when b"1011_1010_001", -- TSX / Implied
		xrg when b"1000_1010_001", -- TXA / Implied
		xrg when b"1001_1010_001", -- TXS / Implied
		yrg when b"1001_1000_001", -- TYA / Implied
		din when others;
		
	-- ALU Input B
	with s_addr select o_alu_b_op <=
		alq when b"0111_0101_010", -- ADC / Zero Page,X
		val when b"0111_1101_010", -- ADC / Absolute,X
		one when b"0111_1101_011", -- ADC / Absolute,X
		val when b"0111_1001_010", -- ADC / Absolute,Y
		one when b"0111_1001_011", -- ADC / Absolute,Y
		alq when b"0110_0001_010", -- ADC / (Indirect,X)
		one when b"0110_0001_011", -- ADC / (Indirect,X)
		one when b"0111_0001_010", -- ADC / (Indirect),Y
		val when b"0111_0001_011", -- ADC / (Indirect),Y
		one when b"0111_0001_100", -- ADC / (Indirect),Y
		alq when b"0011_0101_010", -- AND / Zero Page,X
		val when b"0011_1101_010", -- AND / Absolute,X
		one when b"0011_1101_011", -- AND / Absolute,X
		val when b"0011_1001_010", -- AND / Absolute,Y
		one when b"0011_1001_011", -- AND / Absolute,Y
		alq when b"0010_0001_010", -- AND / (Indirect,X)
		one when b"0010_0001_011", -- AND / (Indirect,X)
		one when b"0011_0001_010", -- AND / (Indirect),Y
		val when b"0011_0001_011", -- AND / (Indirect),Y
		one when b"0011_0001_100", -- AND / (Indirect),Y
		alq when b"0001_0110_010", -- ASL / Zero Page,X
		val when b"0001_1110_010", -- ASL / Absolute,X
		auc when b"0001_1110_011", -- ASL / Absolute,X
		aci when b"1001_0000_010", -- BCC / Relative
		aci when b"1011_0000_010", -- BCS / Relative
		aci when b"1111_0000_010", -- BEQ / Relative
		aci when b"0011_0000_010", -- BMI / Relative
		aci when b"1101_0000_010", -- BNE / Relative
		aci when b"0001_0000_010", -- BPL / Relative
		one when b"0000_0000_001", -- BRK / Implied
		one when b"0000_0000_010", -- BRK / Implied
		one when b"0000_0000_011", -- BRK / Implied
		one when b"0000_0000_101", -- BRK / Implied
		aci when b"0101_0000_010", -- BVC / Relative
		aci when b"0111_0000_010", -- BVS / Relative
		alq when b"1101_0101_010", -- CMP / Zero Page,X
		val when b"1101_1101_010", -- CMP / Absolute,X
		one when b"1101_1101_011", -- CMP / Absolute,X
		val when b"1101_1001_010", -- CMP / Absolute,Y
		one when b"1101_1001_011", -- CMP / Absolute,Y
		alq when b"1100_0001_010", -- CMP / (Indirect,X)
		one when b"1100_0001_011", -- CMP / (Indirect,X)
		one when b"1101_0001_010", -- CMP / (Indirect),Y
		val when b"1101_0001_011", -- CMP / (Indirect),Y
		one when b"1101_0001_100", -- CMP / (Indirect),Y
		one when b"1100_0110_011", -- DEC / Zero Page
		val when b"1101_0110_010", -- DEC / Zero Page,X
		one when b"1101_0110_100", -- DEC / Zero Page,X
		one when b"1100_1110_100", -- DEC / Absolute
		val when b"1101_1110_010", -- DEC / Absolute,X
		auc when b"1101_1110_011", -- DEC / Absolute,X
		one when b"1101_1110_101", -- DEC / Absolute,X
		one when b"1100_1010_001", -- DEX / Implied
		one when b"1000_1000_001", -- DEY / Implied
		alq when b"0101_0101_010", -- EOR / Zero Page,X
		val when b"0101_1101_010", -- EOR / Absolute,X
		one when b"0101_1101_011", -- EOR / Absolute,X
		val when b"0101_1001_010", -- EOR / Absolute,Y
		one when b"0101_1001_011", -- EOR / Absolute,Y
		alq when b"0100_0001_010", -- EOR / (Indirect,X)
		one when b"0100_0001_011", -- EOR / (Indirect,X)
		one when b"0101_0001_010", -- EOR / (Indirect),Y
		val when b"0101_0001_011", -- EOR / (Indirect),Y
		one when b"0101_0001_100", -- EOR / (Indirect),Y
		one when b"1110_0110_011", -- INC / Zero Page
		val when b"1111_0110_010", -- INC / Zero Page,X
		one when b"1111_0110_100", -- INC / Zero Page,X
		one when b"1110_1110_100", -- INC / Absolute
		val when b"1111_1110_010", -- INC / Absolute,X
		auc when b"1111_1110_011", -- INC / Absolute,X
		one when b"1111_1110_101", -- INC / Absolute,X
		one when b"0000_0011_001", -- INT / Implied
		one when b"0000_0011_010", -- INT / Implied
		one when b"0000_0011_011", -- INT / Implied
		one when b"0000_0011_101", -- INT / Implied
		one when b"1110_1000_001", -- INX / Implied
		one when b"1100_1000_001", -- INY / Implied
		one when b"0110_1100_011", -- JMP / Indirect
		one when b"0010_0000_011", -- JSR / Absolute
		one when b"0010_0000_100", -- JSR / Absolute
		alq when b"1011_0101_010", -- LDA / Zero Page,X
		val when b"1011_1101_010", -- LDA / Absolute,X
		one when b"1011_1101_011", -- LDA / Absolute,X
		val when b"1011_1001_010", -- LDA / Absolute,Y
		one when b"1011_1001_011", -- LDA / Absolute,Y
		alq when b"1010_0001_010", -- LDA / (Indirect,X)
		one when b"1010_0001_011", -- LDA / (Indirect,X)
		one when b"1011_0001_010", -- LDA / (Indirect),Y
		val when b"1011_0001_011", -- LDA / (Indirect),Y
		one when b"1011_0001_100", -- LDA / (Indirect),Y
		alq when b"1011_0110_010", -- LDX / Zero Page,Y
		val when b"1011_1110_010", -- LDX / Absolute,Y
		one when b"1011_1110_011", -- LDX / Absolute,Y
		alq when b"1011_0100_010", -- LDY / Zero Page,X
		val when b"1011_1100_010", -- LDY / Absolute,X
		one when b"1011_1100_011", -- LDY / Absolute,X
		alq when b"0101_0110_010", -- LSR / Zero Page,X
		val when b"0101_1110_010", -- LSR / Absolute,X
		auc when b"0101_1110_011", -- LSR / Absolute,X
		one when b"0000_0100_001", -- NMI / Implied
		one when b"0000_0100_010", -- NMI / Implied
		one when b"0000_0100_011", -- NMI / Implied
		one when b"0000_0100_101", -- NMI / Implied
		alq when b"0001_0101_010", -- ORA / Zero Page,X
		val when b"0001_1101_010", -- ORA / Absolute,X
		one when b"0001_1101_011", -- ORA / Absolute,X
		val when b"0001_1001_010", -- ORA / Absolute,Y
		one when b"0001_1001_011", -- ORA / Absolute,Y
		alq when b"0000_0001_010", -- ORA / (Indirect,X)
		one when b"0000_0001_011", -- ORA / (Indirect,X)
		one when b"0001_0001_010", -- ORA / (Indirect),Y
		val when b"0001_0001_011", -- ORA / (Indirect),Y
		one when b"0001_0001_100", -- ORA / (Indirect),Y
		one when b"0100_1000_010", -- PHA / Implied
		one when b"0000_1000_010", -- PHP / Implied
		one when b"0110_1000_010", -- PLA / Implied
		one when b"0010_1000_010", -- PLP / Implied
		alq when b"0011_0110_010", -- ROL / Zero Page,X
		val when b"0011_1110_010", -- ROL / Absolute,X
		auc when b"0011_1110_011", -- ROL / Absolute,X
		alq when b"0111_0110_010", -- ROR / Zero Page,X
		val when b"0111_1110_010", -- ROR / Absolute,X
		auc when b"0111_1110_011", -- ROR / Absolute,X
		one when b"0000_0010_010", -- RST / Implied
		one when b"0100_0000_010", -- RTI / Implied
		one when b"0100_0000_011", -- RTI / Implied
		one when b"0100_0000_100", -- RTI / Implied
		one when b"0110_0000_010", -- RTS / Implied
		one when b"0110_0000_011", -- RTS / Implied
		alq when b"1111_0101_010", -- SBC / Zero Page,X
		val when b"1111_1101_010", -- SBC / Absolute,X
		one when b"1111_1101_011", -- SBC / Absolute,X
		val when b"1111_1001_010", -- SBC / Absolute,Y
		one when b"1111_1001_011", -- SBC / Absolute,Y
		alq when b"1110_0001_010", -- SBC / (Indirect,X)
		one when b"1110_0001_011", -- SBC / (Indirect,X)
		one when b"1111_0001_010", -- SBC / (Indirect),Y
		val when b"1111_0001_011", -- SBC / (Indirect),Y
		one when b"1111_0001_100", -- SBC / (Indirect),Y
		alq when b"1001_0101_010", -- STA / Zero Page,X
		val when b"1001_1101_010", -- STA / Absolute,X
		auc when b"1001_1101_011", -- STA / Absolute,X
		val when b"1001_1001_010", -- STA / Absolute,Y
		auc when b"1001_1001_011", -- STA / Absolute,Y
		alq when b"1000_0001_010", -- STA / (Indirect,X)
		one when b"1000_0001_011", -- STA / (Indirect,X)
		one when b"1001_0001_010", -- STA / (Indirect),Y
		val when b"1001_0001_011", -- STA / (Indirect),Y
		auc when b"1001_0001_100", -- STA / (Indirect),Y
		alq when b"1001_0110_010", -- STX / Zero Page,Y
		alq when b"1001_0100_010", -- STY / Zero Page,X
		din when others;
		
	-- Registers
	with s_addr select o_reg_op <=
		arg when b"0110_1001_001", -- ADC / Immediate
		arg when b"0110_0101_010", -- ADC / Zero Page
		arg when b"0111_0101_011", -- ADC / Zero Page,X
		arg when b"0110_1101_011", -- ADC / Absolute
		arg when b"0111_1101_100", -- ADC / Absolute,X
		arg when b"0111_1001_100", -- ADC / Absolute,Y
		arg when b"0110_0001_101", -- ADC / (Indirect,X)
		arg when b"0111_0001_101", -- ADC / (Indirect),Y
		arg when b"0010_1001_001", -- AND / Immediate
		arg when b"0010_0101_010", -- AND / Zero Page
		arg when b"0011_0101_011", -- AND / Zero Page,X
		arg when b"0010_1101_011", -- AND / Absolute
		arg when b"0011_1101_100", -- AND / Absolute,X
		arg when b"0011_1001_100", -- AND / Absolute,Y
		arg when b"0010_0001_101", -- AND / (Indirect,X)
		arg when b"0011_0001_101", -- AND / (Indirect),Y
		arg when b"0000_1010_001", -- ASL / Accumulator
		srg when b"0000_0000_011", -- BRK / Implied
		xrg when b"1100_1010_001", -- DEX / Implied
		yrg when b"1000_1000_001", -- DEY / Implied
		arg when b"0100_1001_001", -- EOR / Immediate
		arg when b"0100_0101_010", -- EOR / Zero Page
		arg when b"0101_0101_011", -- EOR / Zero Page,X
		arg when b"0100_1101_011", -- EOR / Absolute
		arg when b"0101_1101_100", -- EOR / Absolute,X
		arg when b"0101_1001_100", -- EOR / Absolute,Y
		arg when b"0100_0001_101", -- EOR / (Indirect,X)
		arg when b"0101_0001_101", -- EOR / (Indirect),Y
		srg when b"0000_0011_011", -- INT / Implied
		xrg when b"1110_1000_001", -- INX / Implied
		yrg when b"1100_1000_001", -- INY / Implied
		srg when b"0010_0000_100", -- JSR / Absolute
		arg when b"1010_1001_001", -- LDA / Immediate
		arg when b"1010_0101_010", -- LDA / Zero Page
		arg when b"1011_0101_011", -- LDA / Zero Page,X
		arg when b"1010_1101_011", -- LDA / Absolute
		arg when b"1011_1101_100", -- LDA / Absolute,X
		arg when b"1011_1001_100", -- LDA / Absolute,Y
		arg when b"1010_0001_101", -- LDA / (Indirect,X)
		arg when b"1011_0001_101", -- LDA / (Indirect),Y
		xrg when b"1010_0010_001", -- LDX / Immediate
		xrg when b"1010_0110_010", -- LDX / Zero Page
		xrg when b"1011_0110_011", -- LDX / Zero Page,Y
		xrg when b"1010_1110_011", -- LDX / Absolute
		xrg when b"1011_1110_100", -- LDX / Absolute,Y
		yrg when b"1010_0000_001", -- LDY / Immediate
		yrg when b"1010_0100_010", -- LDY / Zero Page
		yrg when b"1011_0100_011", -- LDY / Zero Page,X
		yrg when b"1010_1100_011", -- LDY / Absolute
		yrg when b"1011_1100_100", -- LDY / Absolute,X
		arg when b"0100_1010_001", -- LSR / Accumulator
		srg when b"0000_0100_011", -- NMI / Implied
		arg when b"0000_1001_001", -- ORA / Immediate
		arg when b"0000_0101_010", -- ORA / Zero Page
		arg when b"0001_0101_011", -- ORA / Zero Page,X
		arg when b"0000_1101_011", -- ORA / Absolute
		arg when b"0001_1101_100", -- ORA / Absolute,X
		arg when b"0001_1001_100", -- ORA / Absolute,Y
		arg when b"0000_0001_101", -- ORA / (Indirect,X)
		arg when b"0001_0001_101", -- ORA / (Indirect),Y
		srg when b"0100_1000_010", -- PHA / Implied
		srg when b"0000_1000_010", -- PHP / Implied
		srg when b"0110_1000_010", -- PLA / Implied
		arg when b"0110_1000_011", -- PLA / Implied
		srg when b"0010_1000_010", -- PLP / Implied
		arg when b"0010_1010_001", -- ROL / Accumulator
		arg when b"0110_1010_001", -- ROR / Accumulator
		srg when b"0100_0000_100", -- RTI / Implied
		srg when b"0110_0000_011", -- RTS / Implied
		arg when b"1110_1001_001", -- SBC / Immediate
		arg when b"1110_0101_010", -- SBC / Zero Page
		arg when b"1111_0101_011", -- SBC / Zero Page,X
		arg when b"1110_1101_011", -- SBC / Absolute
		arg when b"1111_1101_100", -- SBC / Absolute,X
		arg when b"1111_1001_100", -- SBC / Absolute,Y
		arg when b"1110_0001_101", -- SBC / (Indirect,X)
		arg when b"1111_0001_101", -- SBC / (Indirect),Y
		xrg when b"1010_1010_001", -- TAX / Implied
		yrg when b"1010_1000_001", -- TAY / Implied
		xrg when b"1011_1010_001", -- TSX / Implied
		arg when b"1000_1010_001", -- TXA / Implied
		srg when b"1001_1010_001", -- TXS / Implied
		arg when b"1001_1000_001", -- TYA / Implied
		nop when others;
		
	-- Memory Address
	with s_addr select o_addr_op <=
		zaq when b"0110_0101_001", -- ADC / Zero Page
		zaq when b"0111_0101_001", -- ADC / Zero Page,X
		zaq when b"0111_0101_010", -- ADC / Zero Page,X
		aqd when b"0110_1101_010", -- ADC / Absolute
		daq when b"0111_1101_010", -- ADC / Absolute,X
		aqd when b"0111_1101_011", -- ADC / Absolute,X
		daq when b"0111_1001_010", -- ADC / Absolute,Y
		aqd when b"0111_1001_011", -- ADC / Absolute,Y
		zaq when b"0110_0001_001", -- ADC / (Indirect,X)
		zaq when b"0110_0001_010", -- ADC / (Indirect,X)
		zaq when b"0110_0001_011", -- ADC / (Indirect,X)
		daq when b"0110_0001_100", -- ADC / (Indirect,X)
		zaq when b"0111_0001_001", -- ADC / (Indirect),Y
		zaq when b"0111_0001_010", -- ADC / (Indirect),Y
		daq when b"0111_0001_011", -- ADC / (Indirect),Y
		aqd when b"0111_0001_100", -- ADC / (Indirect),Y
		zaq when b"0010_0101_001", -- AND / Zero Page
		zaq when b"0011_0101_001", -- AND / Zero Page,X
		zaq when b"0011_0101_010", -- AND / Zero Page,X
		aqd when b"0010_1101_010", -- AND / Absolute
		daq when b"0011_1101_010", -- AND / Absolute,X
		aqd when b"0011_1101_011", -- AND / Absolute,X
		daq when b"0011_1001_010", -- AND / Absolute,Y
		aqd when b"0011_1001_011", -- AND / Absolute,Y
		zaq when b"0010_0001_001", -- AND / (Indirect,X)
		zaq when b"0010_0001_010", -- AND / (Indirect,X)
		zaq when b"0010_0001_011", -- AND / (Indirect,X)
		daq when b"0010_0001_100", -- AND / (Indirect,X)
		zaq when b"0011_0001_001", -- AND / (Indirect),Y
		zaq when b"0011_0001_010", -- AND / (Indirect),Y
		daq when b"0011_0001_011", -- AND / (Indirect),Y
		aqd when b"0011_0001_100", -- AND / (Indirect),Y
		zaq when b"0000_0110_001", -- ASL / Zero Page
		zvl when b"0000_0110_010", -- ASL / Zero Page
		zvl when b"0000_0110_011", -- ASL / Zero Page
		zaq when b"0001_0110_001", -- ASL / Zero Page,X
		zaq when b"0001_0110_010", -- ASL / Zero Page,X
		zvl when b"0001_0110_011", -- ASL / Zero Page,X
		zvl when b"0001_0110_100", -- ASL / Zero Page,X
		aqd when b"0000_1110_010", -- ASL / Absolute
		adv when b"0000_1110_011", -- ASL / Absolute
		adv when b"0000_1110_100", -- ASL / Absolute
		daq when b"0001_1110_010", -- ASL / Absolute,X
		aqd when b"0001_1110_011", -- ASL / Absolute,X
		adv when b"0001_1110_100", -- ASL / Absolute,X
		adv when b"0001_1110_101", -- ASL / Absolute,X
		zaq when b"0010_0100_001", -- BIT / Zero Page
		aqd when b"0010_1100_010", -- BIT / Absolute
		oad when b"0000_0000_001", -- BRK / Implied
		oad when b"0000_0000_010", -- BRK / Implied
		oad when b"0000_0000_011", -- BRK / Implied
		vaq when b"0000_0000_100", -- BRK / Implied
		vaq when b"0000_0000_101", -- BRK / Implied
		zaq when b"1100_0101_001", -- CMP / Zero Page
		zaq when b"1101_0101_001", -- CMP / Zero Page,X
		zaq when b"1101_0101_010", -- CMP / Zero Page,X
		aqd when b"1100_1101_010", -- CMP / Absolute
		daq when b"1101_1101_010", -- CMP / Absolute,X
		aqd when b"1101_1101_011", -- CMP / Absolute,X
		daq when b"1101_1001_010", -- CMP / Absolute,Y
		aqd when b"1101_1001_011", -- CMP / Absolute,Y
		zaq when b"1100_0001_001", -- CMP / (Indirect,X)
		zaq when b"1100_0001_010", -- CMP / (Indirect,X)
		zaq when b"1100_0001_011", -- CMP / (Indirect,X)
		daq when b"1100_0001_100", -- CMP / (Indirect,X)
		zaq when b"1101_0001_001", -- CMP / (Indirect),Y
		zaq when b"1101_0001_010", -- CMP / (Indirect),Y
		daq when b"1101_0001_011", -- CMP / (Indirect),Y
		aqd when b"1101_0001_100", -- CMP / (Indirect),Y
		zaq when b"1110_0100_001", -- CPX / Zero Page
		aqd when b"1110_1100_010", -- CPX / Absolute
		zaq when b"1100_0100_001", -- CPY / Zero Page
		aqd when b"1100_1100_010", -- CPY / Absolute
		zaq when b"1100_0110_001", -- DEC / Zero Page
		zvl when b"1100_0110_010", -- DEC / Zero Page
		zvl when b"1100_0110_011", -- DEC / Zero Page
		zaq when b"1101_0110_001", -- DEC / Zero Page,X
		zaq when b"1101_0110_010", -- DEC / Zero Page,X
		zvl when b"1101_0110_011", -- DEC / Zero Page,X		
		zvl when b"1101_0110_100", -- DEC / Zero Page,X
		aqd when b"1100_1110_010", -- DEC / Absolute
		adv when b"1100_1110_011", -- DEC / Absolute
		adv when b"1100_1110_100", -- DEC / Absolute
		daq when b"1101_1110_010", -- DEC / Absolute,X
		aqd when b"1101_1110_011", -- DEC / Absolute,X
		adv when b"1101_1110_100", -- DEC / Absolute,X
		adv when b"1101_1110_101", -- DEC / Absolute,X
		zaq when b"0100_0101_001", -- EOR / Zero Page
		zaq when b"0101_0101_001", -- EOR / Zero Page,X
		zaq when b"0101_0101_010", -- EOR / Zero Page,X
		aqd when b"0100_1101_010", -- EOR / Absolute
		daq when b"0101_1101_010", -- EOR / Absolute,X
		aqd when b"0101_1101_011", -- EOR / Absolute,X
		daq when b"0101_1001_010", -- EOR / Absolute,Y
		aqd when b"0101_1001_011", -- EOR / Absolute,Y
		zaq when b"0100_0001_001", -- EOR / (Indirect,X)
		zaq when b"0100_0001_010", -- EOR / (Indirect,X)
		zaq when b"0100_0001_011", -- EOR / (Indirect,X)
		daq when b"0100_0001_100", -- EOR / (Indirect,X)
		zaq when b"0101_0001_001", -- EOR / (Indirect),Y
		zaq when b"0101_0001_010", -- EOR / (Indirect),Y
		daq when b"0101_0001_011", -- EOR / (Indirect),Y
		aqd when b"0101_0001_100", -- EOR / (Indirect),Y
		zaq when b"1110_0110_001", -- INC / Zero Page
		zvl when b"1110_0110_010", -- INC / Zero Page
		zvl when b"1110_0110_011", -- INC / Zero Page
		zaq when b"1111_0110_001", -- INC / Zero Page,X
		zaq when b"1111_0110_010", -- INC / Zero Page,X
		zvl when b"1111_0110_011", -- INC / Zero Page,X		
		zvl when b"1111_0110_100", -- INC / Zero Page,X
		aqd when b"1110_1110_010", -- INC / Absolute
		adv when b"1110_1110_011", -- INC / Absolute
		adv when b"1110_1110_100", -- INC / Absolute
		daq when b"1111_1110_010", -- INC / Absolute,X
		aqd when b"1111_1110_011", -- INC / Absolute,X
		adv when b"1111_1110_100", -- INC / Absolute,X
		adv when b"1111_1110_101", -- INC / Absolute,X
		oad when b"0000_0011_001", -- INT / Implied
		oad when b"0000_0011_010", -- INT / Implied
		oad when b"0000_0011_011", -- INT / Implied
		vaq when b"0000_0011_100", -- INT / Implied
		vaq when b"0000_0011_101", -- INT / Implied
		daq when b"0110_1100_010", -- JMP / Indirect
		vaq when b"0110_1100_011", -- JMP / Indirect
		oaq when b"0010_0000_001", -- JSR / Absolute
		oaq when b"0010_0000_010", -- JSR / Absolute
		oaq when b"0010_0000_011", -- JSR / Absolute
		zaq when b"1010_0101_001", -- LDA / Zero Page
		zaq when b"1011_0101_001", -- LDA / Zero Page,X
		zaq when b"1011_0101_010", -- LDA / Zero Page,X
		aqd when b"1010_1101_010", -- LDA / Absolute
		daq when b"1011_1101_010", -- LDA / Absolute,X
		aqd when b"1011_1101_011", -- LDA / Absolute,X
		daq when b"1011_1001_010", -- LDA / Absolute,Y
		aqd when b"1011_1001_011", -- LDA / Absolute,Y
		zaq when b"1010_0001_001", -- LDA / (Indirect,X)
		zaq when b"1010_0001_010", -- LDA / (Indirect,X)
		zaq when b"1010_0001_011", -- LDA / (Indirect,X)
		daq when b"1010_0001_100", -- LDA / (Indirect,X)
		zaq when b"1011_0001_001", -- LDA / (Indirect),Y
		zaq when b"1011_0001_010", -- LDA / (Indirect),Y
		daq when b"1011_0001_011", -- LDA / (Indirect),Y
		aqd when b"1011_0001_100", -- LDA / (Indirect),Y
		zaq when b"1010_0110_001", -- LDX / Zero Page
		zaq when b"1011_0110_001", -- LDX / Zero Page,Y
		zaq when b"1011_0110_010", -- LDX / Zero Page,Y
		aqd when b"1010_1110_010", -- LDX / Absolute
		daq when b"1011_1110_010", -- LDX / Absolute,Y
		aqd when b"1011_1110_011", -- LDX / Absolute,Y
		zaq when b"1010_0100_001", -- LDY / Zero Page
		zaq when b"1011_0100_001", -- LDY / Zero Page,X
		zaq when b"1011_0100_010", -- LDY / Zero Page,X
		aqd when b"1010_1100_010", -- LDY / Absolute
		daq when b"1011_1100_010", -- LDY / Absolute,X
		aqd when b"1011_1100_011", -- LDY / Absolute,X
		zaq when b"0100_0110_001", -- LSR / Zero Page
		zvl when b"0100_0110_010", -- LSR / Zero Page
		zvl when b"0100_0110_011", -- LSR / Zero Page
		zaq when b"0101_0110_001", -- LSR / Zero Page,X
		zaq when b"0101_0110_010", -- LSR / Zero Page,X
		zvl when b"0101_0110_011", -- LSR / Zero Page,X
		zvl when b"0101_0110_100", -- LSR / Zero Page,X
		aqd when b"0100_1110_010", -- LSR / Absolute
		adv when b"0100_1110_011", -- LSR / Absolute
		adv when b"0100_1110_100", -- LSR / Absolute
		daq when b"0101_1110_010", -- LSR / Absolute,X
		aqd when b"0101_1110_011", -- LSR / Absolute,X
		adv when b"0101_1110_100", -- LSR / Absolute,X
		adv when b"0101_1110_101", -- LSR / Absolute,X
		oad when b"0000_0100_001", -- NMI / Implied
		oad when b"0000_0100_010", -- NMI / Implied
		oad when b"0000_0100_011", -- NMI / Implied
		vaq when b"0000_0100_100", -- NMI / Implied
		vaq when b"0000_0100_101", -- NMI / Implied
		zaq when b"0000_0101_001", -- ORA / Zero Page
		zaq when b"0001_0101_001", -- ORA / Zero Page,X
		zaq when b"0001_0101_010", -- ORA / Zero Page,X
		aqd when b"0000_1101_010", -- ORA / Absolute
		daq when b"0001_1101_010", -- ORA / Absolute,X
		aqd when b"0001_1101_011", -- ORA / Absolute,X
		daq when b"0001_1001_010", -- ORA / Absolute,Y
		aqd when b"0001_1001_011", -- ORA / Absolute,Y
		zaq when b"0000_0001_001", -- ORA / (Indirect,X)
		zaq when b"0000_0001_010", -- ORA / (Indirect,X)
		zaq when b"0000_0001_011", -- ORA / (Indirect,X)
		daq when b"0000_0001_100", -- ORA / (Indirect,X)
		zaq when b"0001_0001_001", -- ORA / (Indirect),Y
		zaq when b"0001_0001_010", -- ORA / (Indirect),Y
		daq when b"0001_0001_011", -- ORA / (Indirect),Y
		aqd when b"0001_0001_100", -- ORA / (Indirect),Y
		oaq when b"0100_1000_001", -- PHA / Implied
		oaq when b"0000_1000_001", -- PHP / Implied
		oaq when b"0110_1000_001", -- PLA / Implied
		oaq when b"0110_1000_010", -- PLA / Implied
		oaq when b"0010_1000_001", -- PLP / Implied
		oaq when b"0010_1000_010", -- PLP / Implied
		zaq when b"0010_0110_001", -- ROL / Zero Page
		zvl when b"0010_0110_010", -- ROL / Zero Page
		zvl when b"0010_0110_011", -- ROL / Zero Page
		zaq when b"0011_0110_001", -- ROL / Zero Page,X
		zaq when b"0011_0110_010", -- ROL / Zero Page,X
		zvl when b"0011_0110_011", -- ROL / Zero Page,X
		zvl when b"0011_0110_100", -- ROL / Zero Page,X
		aqd when b"0010_1110_010", -- ROL / Absolute
		adv when b"0010_1110_011", -- ROL / Absolute
		adv when b"0010_1110_100", -- ROL / Absolute
		daq when b"0011_1110_010", -- ROL / Absolute,X
		aqd when b"0011_1110_011", -- ROL / Absolute,X
		adv when b"0011_1110_100", -- ROL / Absolute,X
		adv when b"0011_1110_101", -- ROL / Absolute,X
		zaq when b"0110_0110_001", -- ROR / Zero Page
		zvl when b"0110_0110_010", -- ROR / Zero Page
		zvl when b"0110_0110_011", -- ROR / Zero Page
		zaq when b"0111_0110_001", -- ROR / Zero Page,X
		zaq when b"0111_0110_010", -- ROR / Zero Page,X
		zvl when b"0111_0110_011", -- ROR / Zero Page,X
		zvl when b"0111_0110_100", -- ROR / Zero Page,X
		aqd when b"0110_1110_010", -- ROR / Absolute
		adv when b"0110_1110_011", -- ROR / Absolute
		adv when b"0110_1110_100", -- ROR / Absolute
		daq when b"0111_1110_010", -- ROR / Absolute,X
		aqd when b"0111_1110_011", -- ROR / Absolute,X
		adv when b"0111_1110_100", -- ROR / Absolute,X
		adv when b"0111_1110_101", -- ROR / Absolute,X
		vaq when b"0000_0010_001", -- RST / Implied
		vaq when b"0000_0010_010", -- RST / Implied
		oaq when b"0100_0000_001", -- RTI / Implied
		oaq when b"0100_0000_010", -- RTI / Implied
		oaq when b"0100_0000_011", -- RTI / Implied
		oaq when b"0100_0000_100", -- RTI / Implied
		oaq when b"0110_0000_001", -- RTS / Implied
		oaq when b"0110_0000_010", -- RTS / Implied
		oaq when b"0110_0000_011", -- RTS / Implied
		zaq when b"1110_0101_001", -- SBC / Zero Page
		zaq when b"1111_0101_001", -- SBC / Zero Page,X
		zaq when b"1111_0101_010", -- SBC / Zero Page,X
		aqd when b"1110_1101_010", -- SBC / Absolute
		daq when b"1111_1101_010", -- SBC / Absolute,X
		aqd when b"1111_1101_011", -- SBC / Absolute,X
		daq when b"1111_1001_010", -- SBC / Absolute,Y
		aqd when b"1111_1001_011", -- SBC / Absolute,Y
		zaq when b"1110_0001_001", -- SBC / (Indirect,X)
		zaq when b"1110_0001_010", -- SBC / (Indirect,X)
		zaq when b"1110_0001_011", -- SBC / (Indirect,X)
		daq when b"1110_0001_100", -- SBC / (Indirect,X)
		zaq when b"1111_0001_001", -- SBC / (Indirect),Y
		zaq when b"1111_0001_010", -- SBC / (Indirect),Y
		daq when b"1111_0001_011", -- SBC / (Indirect),Y
		aqd when b"1111_0001_100", -- SBC / (Indirect),Y
		zaq when b"1000_0101_001", -- STA / Zero Page
		zaq when b"1001_0101_001", -- STA / Zero Page,X
		zaq when b"1001_0101_010", -- STA / Zero Page,X
		aqd when b"1000_1101_010", -- STA / Absolute
		daq when b"1001_1101_010", -- STA / Absolute,X
		aqd when b"1001_1101_011", -- STA / Absolute,X
		daq when b"1001_1001_010", -- STA / Absolute,Y
		aqd when b"1001_1001_011", -- STA / Absolute,Y
		zaq when b"1000_0001_001", -- STA / (Indirect,X)
		zaq when b"1000_0001_010", -- STA / (Indirect,X)
		zaq when b"1000_0001_011", -- STA / (Indirect,X)
		daq when b"1000_0001_100", -- STA / (Indirect,X)
		zaq when b"1001_0001_001", -- STA / (Indirect),Y
		zaq when b"1001_0001_010", -- STA / (Indirect),Y
		daq when b"1001_0001_011", -- STA / (Indirect),Y
		aqd when b"1001_0001_100", -- STA / (Indirect),Y
		zaq when b"1000_0110_001", -- STX / Zero Page
		zaq when b"1001_0110_001", -- STX / Zero Page,Y
		zaq when b"1001_0110_010", -- STX / Zero Page,Y
		aqd when b"1000_1110_010", -- STX / Absolute
		zaq when b"1000_0100_001", -- STY / Zero Page
		zaq when b"1001_0100_001", -- STY / Zero Page,X
		zaq when b"1001_0100_010", -- STY / Zero Page,X
		aqd when b"1000_1100_010", -- STY / Absolute
		nop when others;
		
	-- Branching
	o_branch_at_cycle_1 <= (s_addr(7 downto 0) = b"1_0000_001");
	o_branch_at_cycle_2 <= (s_addr(7 downto 0) = b"1_0000_010");

	s_addr <= std_ulogic_vector(i_opcode & i_cycle);
	
end;
