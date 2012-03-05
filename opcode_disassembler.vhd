library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use std.textio.all;

ENTITY opcode_disassembler IS
    PORT (
        Opcode : in Std_Logic_Vector(31 downto 0));
END opcode_disassembler;

ARCHITECTURE netlist OF opcode_disassembler IS
	signal opcode_disassembled : String(31 downto 1);
BEGIN
--pragma translate_off
	process(Opcode)
		variable d,a,b,perml, permk, permj, permi: String(2 downto 1);
		--variable md0, md1, md2, md3, ma0, ma1, ma2, ma3: Integer;
		variable md, ma : std_logic_vector(3 downto 0);
		--variable perml, permk, permj, permi : std_logic_vector(1 downto 0);
		variable mds, mas : String (9 downto 1); 
		variable imm16 : String(4 downto 1);
		variable imm16vec : Std_Logic_vector(3 downto 0);
	begin
--pragma translate_on
          opcode_disassembled <= (others => ' ');
--pragma translate_off
          if (Opcode(0) /= '0' and Opcode(0) /= '1') then
             opcode_disassembled<="unknowns in the opcode         ";
          else
		d:=(others => ' ');
		a:=(others => ' ');
		b:=(others => ' ');
		perml:=(others => ' ');
		permk:=(others => ' ');
		permj:=(others => ' ');
		permi:=(others => ' ');
		d(2 downto (3-integer'image(conv_integer(unsigned(Opcode(25 downto 21))))'right)) := integer'image(conv_integer(unsigned(Opcode(25 downto 21))));
		a(2 downto (3-integer'image(conv_integer(unsigned(Opcode(20 downto 16))))'right)) := integer'image(conv_integer(unsigned(Opcode(20 downto 16))));
		b(2 downto (3-integer'image(conv_integer(unsigned(Opcode(15 downto 11))))'right)) := integer'image(conv_integer(unsigned(Opcode(15 downto 11))));
		perml(2 downto (3-integer'image(conv_integer(unsigned(Opcode(7 downto 6))))'right)) := integer'image(conv_integer(unsigned(Opcode(7 downto 6))));
		permk(2 downto (3-integer'image(conv_integer(unsigned(Opcode(5 downto 4))))'right)) := integer'image(conv_integer(unsigned(Opcode(5 downto 4))));
		permj(2 downto (3-integer'image(conv_integer(unsigned(Opcode(3 downto 2))))'right)) := integer'image(conv_integer(unsigned(Opcode(3 downto 2))));
		permi(2 downto (3-integer'image(conv_integer(unsigned(Opcode(1 downto 0))))'right)) := integer'image(conv_integer(unsigned(Opcode(1 downto 0))));
			
		for i in 0 to 4 loop
			if not ((Opcode(21+i)='1') or (Opcode(21+i)='0')) then
				d:=(others => 'X');
			end if;
                        if not ((Opcode(16+i)='1') or (Opcode(16+i)='0')) then
                                a:=(others => 'X');
                        end if;
                        if not ((Opcode(11+i)='1') or (Opcode(11+i)='0')) then
                                b:=(others => 'X');
                        end if;
		end loop;
		--permi := Opcode(1 downto 0);
		--permj := Opcode(3 downto 2);
		--permk := Opcode(5 downto 4);
		--perml := Opcode(7 downto 6);
		md := Opcode(24 downto 21);
		case md is
			when "0000"   => mds := "[0,1,2,3]";
			when "0001"   => mds := "[1,2,3]  ";
			when "0010"   => mds := "[0,2,3]  ";
			when "0011"   => mds := "[2,3]    ";
			when "0100"   => mds := "[0,1,3]  ";
			when "0101"   => mds := "[1,3]    ";
			when "0110"   => mds := "[0,3]    ";
			when "0111"   => mds := "[3]      ";
			when "1000"   => mds := "[0,1,2]  ";
			when "1001"   => mds := "[1,2]    ";
			when "1010"   => mds := "[0,2]    ";
			when "1011"   => mds := "[2]      ";
			when "1100"   => mds := "[0,1]    ";
			when "1101"   => mds := "[1]      ";
			when "1110"   => mds := "[0]      ";
			when "1111"   => mds := "[]       ";
			when others   => mds := "X        ";
		end case;
		ma := Opcode(19 downto 16);
		case ma is
			when "0000"   => mas := "[0,1,2,3]";
			when "0001"   => mas := "[1,2,3]  ";
			when "0010"   => mas := "[0,2,3]  ";
			when "0011"   => mas := "[2,3]    ";
			when "0100"   => mas := "[0,1,3]  ";
			when "0101"   => mas := "[1,3]    ";
			when "0110"   => mas := "[0,3]    ";
			when "0111"   => mas := "[3]      ";
			when "1000"   => mas := "[0,1,2]  ";
			when "1001"   => mas := "[1,2]    ";
			when "1010"   => mas := "[0,2]    ";
			when "1011"   => mas := "[2]      ";
			when "1100"   => mas := "[0,1]    ";
			when "1101"   => mas := "[1]      ";
			when "1110"   => mas := "[0]      ";
			when "1111"   => mas := "[]       ";
			when others   => mas := "X        ";
		end case;

		for i in 0 to 3 loop
			imm16vec:= To_X01Z(Opcode(4*i+3 downto 4*i));
			case imm16vec is
				when x"0"   => imm16(i+1) := '0';
				when x"1"   => imm16(i+1) := '1';
				when x"2"   => imm16(i+1) := '2';
				when x"3"   => imm16(i+1) := '3';
				when x"4"   => imm16(i+1) := '4';
				when x"5"   => imm16(i+1) := '5';
				when x"6"   => imm16(i+1) := '6';
				when x"7"   => imm16(i+1) := '7';
				when x"8"   => imm16(i+1) := '8';
				when x"9"   => imm16(i+1) := '9';
				when x"A"   => imm16(i+1) := 'A';
				when x"B"   => imm16(i+1) := 'B';
				when x"C"   => imm16(i+1) := 'C';
				when x"D"   => imm16(i+1) := 'D';
				when x"E"   => imm16(i+1) := 'E';
				when x"F"   => imm16(i+1) := 'F';
				when "ZZZZ" => imm16(i+1) := 'Z';
				when others => imm16(i+1) := 'X';
			end case;
		end loop;
		case Opcode(31 downto 26) is
			when "010000" => opcode_disassembled<="ld.w $"&d&",0x"&imm16&"($"&a&")           ";
			when "010001" => opcode_disassembled<="st.w $"&d&",0x"&imm16&"($"&a&")           ";
			when "011100" => opcode_disassembled<="ld.b $"&d&",0x"&imm16&"($"&a&")           ";
			when "011101" => opcode_disassembled<="st.b $"&d&",0x"&imm16&"($"&a&")           ";

			when "100000" => opcode_disassembled<="ldih $"&d&""&mas&",0x"&imm16&"       ";
			when "100001" => opcode_disassembled<="ldil $"&d&""&mas&",0x"&imm16&"       ";

			when "110000" => opcode_disassembled<="jmp $"&a&"                        ";
			when "110100" => opcode_disassembled<="bra 0x"&imm16&"                     ";
			when "110101" => opcode_disassembled<="bz 0x"&imm16&",$"&a&""&mds&"         ";
			when "110110" => opcode_disassembled<="bnz 0x"&imm16&",$"&a&""&mds&"        ";
			
			--when "110001" => opcode_disassembled<="jz $"&a&", $"&b&"              ";
			when "110010" => opcode_disassembled<="nop                            ";
			when "110011" => opcode_disassembled<="call $"&d&",$"&a&"                   ";
			when "110111" => opcode_disassembled<="bl $"&d&",0x"&imm16&"                  ";

			when "001111" => opcode_disassembled<="addi $"&d&",$"&a&",0x"&imm16&"            ";
                        when "000000" => opcode_disassembled<="add $"&d&",$"&a&",$"&b&"                ";
			when "000001" => opcode_disassembled<="sub $"&d&",$"&a&",$"&b&"                ";
                        when "000010" => opcode_disassembled<="and $"&d&",$"&a&",$"&b&"                ";
                        when "000011" => opcode_disassembled<="or $"&d&",$"&a&",$"&b&"                 ";
                       -- when "000100" => opcode_disassembled<="cp $"&d&",$"&a&"                     ";
                        when "000101" => opcode_disassembled<="not $"&d&",$"&a&"                    ";
			when "001011" => opcode_disassembled<="sari $"&d&",$"&a&",0x"&imm16&"            ";
			when "000110" => opcode_disassembled<="sal $"&d&",$"&a&"                    ";
			when "000111" => opcode_disassembled<="sar $"&d&",$"&a&"                    ";
			when "001000" => opcode_disassembled<="mul $"&d&",$"&a&",$"&b&"                ";
			when "001001" => opcode_disassembled<="perm $"&d&",$"&a&"["&permi&","&permj&","&permk&","&perml&"]      ";
			when "001010" => opcode_disassembled<="rdc8 $"&d&",$"&a&"                   ";
			when "001100" => opcode_disassembled<="tge $"&d&",$"&a&",$"&b&"                ";
			when "001101" => opcode_disassembled<="tse $"&d&",$"&a&",$"&b&"                ";
			when "111111" => opcode_disassembled<="rfe                            ";

			when others   => opcode_disassembled<="illegal opcode                 ";
		end case;
              end if;
	end process;
--pragma translate_on
END netlist;
