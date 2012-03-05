library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
library work;
use work.types.all;

entity instr_decode is
	port (
		clk: in std_logic;
		ctrl: in control; 
		ins: in instruction; 
		instrn_decode_out: out instruction_decoded; 
		operand_output: out operand_type; 
		write_back_ex: in write_back;
		branch : 	in  std_logic;
		write_back_input: in write_back
	     );
end entity;


architecture behav of instr_decode is
type ram_type is array(0 to 31) of std_logic_vector(31 downto 0); -- infereing ram block.
signal ram : ram_type := (others =>(others => '0'));
signal invalidate_next_ins, nop : std_logic;
begin
process (clk)
begin
    if (clk'event and clk = '1') then
      	if (ctrl.res = '1') then
--		nop(instrn_decode_out); -- resets all the control signals.
		instrn_decode_out.instr.pc <= (others => '0');
		instrn_decode_out.instr.ir <= (others => '0');
		instrn_decode_out.idx_a <= (others => '0');
		instrn_decode_out.idx_b <= (others => '0');
		instrn_decode_out.idx_d <= (others => '0');
		instrn_decode_out.alu_op<= (others => '0');
                instrn_decode_out.instr.valid <= '0';
                instrn_decode_out.load <= '0';
                instrn_decode_out.loadi <= '0'; 
                instrn_decode_out.store <= '0';
                instrn_decode_out.alu <= '0';
                instrn_decode_out.jmp <= '0';
                instrn_decode_out.jz <= '0';
                instrn_decode_out.jnz <= '0';
                instrn_decode_out.relative <= '0';
                instrn_decode_out.call <= '0';
                instrn_decode_out.rfe <= '0';
		invalidate_next_ins <= '0';
      else
	
	if (write_back_input.d_valid = '1') then
		ram(to_integer(unsigned(write_back_input.idx_d ))) <= write_back_input.d;
	end if;
	if branch = '1' then
		invalidate_next_ins <= '1';
		if write_back_ex.d_valid = '1' then
			ram(to_integer(unsigned(write_back_ex.idx_d ))) <= write_back_ex.d;
		end if;
	end if;    
        if (ins.valid = '1' and ctrl.stall = '0') then-- instruction is a valid instruction
            instrn_decode_out.loadi <= ins.valid and active_high(ins.ir(31 downto 27) = "10000");
            instrn_decode_out.load <= ins.valid and active_high(ins.ir(31 downto 26) = "010000");
            instrn_decode_out.store <= ins.valid and active_high(ins.ir(31 downto 26) = "010001");
            instrn_decode_out.jmp <= ins.valid and (active_high(ins.ir(31 downto 26) = "110000") or active_high(ins.ir(31 downto 26) = "110100"));
            instrn_decode_out.jz <= ins.valid and active_high(ins.ir(31 downto 26) = "110101");
            instrn_decode_out.jnz <= ins.valid and active_high(ins.ir(31 downto 26) = "110110");
            instrn_decode_out.call <= ins.valid and (active_high(ins.ir(31 downto 26) = "110011") or active_high(ins.ir(31 downto 26) = "110111"));
            instrn_decode_out.relative <= ins.valid and active_high(ins.ir(31 downto 28) = "1101");
            instrn_decode_out.alu <= ins.valid and active_high(ins.ir(31 downto 30) = "00");
            
            instrn_decode_out.idx_a <= ins.ir(20 downto 16);
            instrn_decode_out.idx_b <= ins.ir(15 downto 11);
            instrn_decode_out.idx_d <= ins.ir(25 downto 21);
            instrn_decode_out.alu_op <= ins.ir(29 downto 26); 
            instrn_decode_out.instr.pc <= ins.pc;
            instrn_decode_out.instr.ir <= ins.ir;
           
            operand_output.i <=  ins.ir(15 downto 0);
            
	    if branch = '1' or invalidate_next_ins = '1' then
		    instrn_decode_out.instr.valid <= '0';
		    invalidate_next_ins <= '0';	
	    else
		instrn_decode_out.instr.valid <= '1';	
		invalidate_next_ins <= '0';
	    end if;

            --four cases arise here:
            --no WB and instrn is not loadi
            --no WB and instrn is loadi
            --WB and instrn is not loadi
            --WB and instrn is loadi
            if (write_back_input.d_valid = '0') then			--no WB
	      if (ins.ir(31 downto 26) = "010001") then
                operand_output.a <= ram(to_integer(unsigned(ins.ir(20 downto 16))));
		operand_output.b <= ram(to_integer(unsigned(ins.ir(25 downto 21)))); --store op!
              elsif(ins.ir(31 downto 27) /= "10000") then	--no WB and no loadi
                operand_output.a <= ram(to_integer(unsigned(ins.ir(20 downto 16))));
                operand_output.b <= ram(to_integer(unsigned(ins.ir(15 downto 11))));
              elsif(ins.ir(31 downto 27) = "10000") then	--no WB but loadi
                operand_output.a <= ram(to_integer(unsigned(ins.ir(25 downto 21))));
                operand_output.b <= ram(to_integer(unsigned(ins.ir(15 downto 11))));
              end if;
              
            elsif(write_back_input.d_valid = '1') then			--WB
	      
	       if (ins.ir(31 downto 26) = "010001") then	--wb and store
		ram(to_integer(unsigned(write_back_input.idx_d ))) <= write_back_input.d;
		if (write_back_input.idx_d = ins.ir(25 downto 21) ) then 
                	operand_output.a <= ram(to_integer(unsigned(ins.ir(20 downto 16))));
			operand_output.b <= write_back_input.d ; --store op!              
		elsif (write_back_input.idx_d = ins.ir(20 downto 16) ) then 
                	operand_output.a <= write_back_input.d ;
			operand_output.b <= ram(to_integer(unsigned(ins.ir(25 downto 21)))); --store op!     
		else
		        operand_output.a <= ram(to_integer(unsigned(ins.ir(20 downto 16))));
			operand_output.b <= ram(to_integer(unsigned(ins.ir(25 downto 21)))); --store op!		
		end if;		
	      else
              
	       if(ins.ir(31 downto 27) /= "10000") then			--WB and no loadi
                 ram(to_integer(unsigned(write_back_input.idx_d ))) <= write_back_input.d;
                                        --WB addr = regA addr.

                 if (write_back_input.idx_d = ins.ir(20 downto 16) ) then 
                   operand_output.a <= write_back_input.d ;
                   operand_output.b <= ram (to_integer(unsigned(ins.ir(15 downto 11))));
					--WB addr = regB addr.

                 elsif (write_back_input.idx_d = ins.ir(15 downto 11) ) then 
                   operand_output.b <= write_back_input.d ;
                   operand_output.a <= ram (to_integer(unsigned(ins.ir(20 downto 16))));

		 else	
		   operand_output.a <= ram (to_integer(unsigned(ins.ir(20 downto 16))));
		   operand_output.b <= ram (to_integer(unsigned(ins.ir(15 downto 11))));
                 end if;            
                
               elsif(ins.ir(31 downto 27) = "10000") then		--WB and loadi
                 ram(to_integer(unsigned(write_back_input.idx_d ))) <= write_back_input.d;
		 operand_output.b <= ram (to_integer(unsigned(ins.ir(15 downto 11)))); 
                                        --WB addr = destination reg address.
                 if (write_back_input.idx_d = ins.ir(25 downto 21) ) then 
                   operand_output.a <= write_back_input.d ;  
		 else 
		   operand_output.a <= ram (to_integer(unsigned(ins.ir(25 downto 21))));
                 end if;
               end if;
	      end if;
            end if;    

--	  elsif (ins.valid = '1' and ctrl.stall = '0') and nop = '1' then
--		nop <= '0';
          end if;
	      

  end if;
end if;
end process;

end behav;
