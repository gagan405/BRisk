library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port(	a:	in std_logic_vector(31 downto 0); -- 32 bit signed input a
	b:	in std_logic_vector(31 downto 0); -- 32 bit signed input b
	s:      in std_logic_vector(3 downto 0);  -- 3 bit select input of ALU
        i:      in std_logic_vector(15 downto 0); -- 16 bit Immediate valeu of the opcode.
	q:	out std_logic_vector(31 downto 0);-- 32 bit signed result of ALU operation
	z_out: out std_logic  -- zero signed which is set when b = 0;
);
end alu;


architecture behv of alu is
begin
  process(a, b, s, i) is
    --variable b_temp: std_logic_vector (31 downto 0);
    variable b_temp: integer;
    variable b_temp_abs : natural;
    variable i_signext : std_logic_vector (31 downto 0);
    --constant zero_value : std_logic_vector
    begin
      if (TO_INTEGER(signed(b))= 0 and (s /= "1111") and (s /= "0101") and (s /= "1011")) then
        z_out <= '1'; -- the zero signal of b
      elsif(((s = "1111") or (s = "1011")) and (TO_INTEGER(signed(i))= 0)) then
        z_out <= '1'; 
      else
        z_out <= '0';
      end if;
      
      case s is
        when "0000" => -- signed addition of a and b 
          q <= std_logic_vector (signed (a) + signed(b));   
        when "0001" => -- signed subtraction of a and B (a -b)
          q <= std_logic_vector (signed (a)- signed(b));
        when "0010" => -- logical AND opreation of a and b 
          q <= a and b;
        when "0011" => -- logical OR operation of a and b
          q <= a or b;
        when "0101" => -- complement of a.
          q <= not (a);
        when "0110" => --SAL Shift left a by b times if b>0 other wise do shift right operation.
          if (TO_INTEGER(signed(b)) > 0) then
            q <= std_logic_vector(SHIFT_LEFT(signed(a), (TO_INTEGER(signed(b))))); -- the shifting is done inclusing the sign bit, so the result can be positive or negative.
          else
            b_temp := TO_INTEGER(signed(b));-- converting b to integer value.
            b_temp_abs := abs(b_temp);  -- finding the absolute value
            q <= std_logic_vector(shift_right(signed(a), b_temp_abs)); -- if b<0, perform right shift operation.
          end if;
        when "0111" => -- SAR Shift Right a by b times if b>0 otherwise do shift left operation.
          if (TO_INTEGER(signed (b)) > 0) then
            q <= std_logic_vector(shift_right(signed(a), TO_INTEGER(signed(b)))); -- Shift right a by b times and fills left vacant bits with MSB a(31)
          else
            b_temp := TO_INTEGER(signed(b));
            b_temp_abs := abs(b_temp);
            q <= std_logic_vector(SHIFT_LEFT(signed(a) , b_temp_abs)); -- if b < 0 perform shift left operation
          end if;
        when "1111" => -- ADDI operation Ra + Signext(i)
          if (i(15) = '1') then
            i_signext := x"ffff" & i;
          elsif(i(15) = '0') then
            i_signext := x"0000" & i;
          end if;
            q <= std_logic_vector (signed (a) + signed(i_signext));

        when "1011" => -- SARI Shift Right a by i times if i>0 otherwise do shift left operation.
          if (TO_INTEGER(signed (i)) > 0) then
            q <= std_logic_vector(shift_right(signed(a), TO_INTEGER(signed(i)))); -- Shift right a by b times and fills left vacant bits with MSB a(31)
          else
            b_temp := TO_INTEGER(signed(i));
            b_temp_abs := abs(b_temp);
            q <= std_logic_vector(SHIFT_LEFT(signed(a) , b_temp_abs)); -- if i < 0 perform shift left operation
          end if;
 
        when others =>
          z_out <= '0'; -- the zero signal of b
          q <= (others => '0'); -- clearing output q in any other case.                         
    end case;
  end process;
end behv;
  
