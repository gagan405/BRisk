library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
library work;
use work.types.all;

entity fw_mux is
  port(
    idx_a       :       in Tidx;
    idx_b       :       in Tidx;
    idx_d_ex    :       in Tidx;
    idx_d_ls    :       in Tidx;
    op_a_id     :       in Tdata;
    op_b_id     :       in Tdata;
    ex_out      :       in Tdata;
    ls_out      :       in Tdata;
    wb_valid    :       in std_logic;
    ex_valid 	:	in std_logic;

    op_a        :       out Tdata;
    op_b        :       out Tdata
    );
end fw_mux;


architecture behavioral of fw_mux is

begin  -- behavioral

select_operand: process (idx_a, idx_b, idx_d_ex, idx_d_ls, op_a_id, op_b_id, ex_out, ls_out, wb_valid, ex_valid)
begin  -- process select

  if (ex_valid = '1') and ((idx_a xor idx_d_ex) = "00000") then
    op_a <= ex_out; 
  elsif (wb_valid = '1') and ((idx_a xor idx_d_ls) = "00000") then
    op_a <= ls_out;
  else
    op_a <= op_a_id;
  end if;

  if ((idx_b xor idx_d_ex) = "00000") and (ex_valid = '1') then
    op_b <= ex_out; 
  elsif ((idx_b xor idx_d_ls) = "00000") and (wb_valid = '1')  then
    op_b <= ls_out;
  else
    op_b <= op_b_id;
  end if;
  
end process;

end behavioral;
