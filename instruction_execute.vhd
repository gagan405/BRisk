library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
library work;
use work.types.all;

entity instr_exe is
  port (
       clk: in std_logic;
       ctrl: in control; 
       instruction_decode_in: in instruction_decoded; 
       instruction_decode_out: out instruction_decoded; 
       operand_in: in operand_type;
       branch_out: out branch; 
       wb_in : in write_back;	
       write_back_ex: out write_back;
       exe_out : out std_logic_vector(31 downto 0); --output of the exe unit.
       store_data_out: out Tdata --data to be written to memory
 );
end entity;

architecture behav of instr_exe is

signal ex_out_tmp : std_logic_vector(31 downto 0);
signal ins_decode_tmp : instruction_decoded; 
signal branch_out_tmp : branch;
-- alu component-----------------------------------------------------------------
signal alu_a, alu_b, alu_out : std_logic_vector(31 downto 0);
signal alu_sel : std_logic_vector(3 downto 0); 
signal alu_z,branch_clear,ex_valid_sig : std_logic;
signal alu_i : std_logic_vector(15 downto 0);
signal signext, signext_shift, bl_temp, call_temp : std_logic_vector(31 downto 0);

signal operand_a, operand_b : Tdata;

component  alu
	port(
	a:	in std_logic_vector(31 downto 0);
	b:	in std_logic_vector(31 downto 0); 
	s:      in std_logic_vector(3 downto 0);  
	i:      in std_logic_vector (15 downto 0);
	q:	out std_logic_vector(31 downto 0);
	z_out:  out std_logic 
	);
end component;

component fw_mux is
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
    ex_valid	: 	in std_logic;
    op_a        :       out Tdata;
    op_b        :       out Tdata
    );
end component;

begin

mux_inst : fw_mux
port map (
    idx_a       => 	instruction_decode_in.idx_a,
    idx_b       => 	instruction_decode_in.idx_b,
    idx_d_ex    => 	ins_decode_tmp.idx_d,
    idx_d_ls    =>      wb_in.idx_d,
    op_a_id     =>   	operand_in.a,
    op_b_id     =>   	operand_in.b,
    ex_out      =>      ex_out_tmp,
    ls_out      =>	wb_in.d,
    wb_valid     =>	wb_in.d_valid,
    ex_valid	=>	ex_valid_sig,
    op_a        =>       operand_a,
    op_b        =>    operand_b

);


alu_exe_inst: alu
port map (
	a => alu_a,
	b => alu_b,
	i => alu_i,
	s => alu_sel,
	q => alu_out,
	z_out => alu_z
	);
signext <= (x"ffff" & operand_in.i) when (operand_in.i(15) = '1')else (x"0000" & operand_in.i);-- sign extension of the immediate value.
signext_shift <= std_logic_vector(SHIFT_LEFT(signed(signext), 2)); -- shift left by 2 bits.

alu_a <= operand_a;
alu_b <= operand_b;
alu_i <= operand_in.i;
alu_sel <= instruction_decode_in.alu_op;

ex_valid_sig <= ins_decode_tmp.loadi or ins_decode_tmp.alu or ins_decode_tmp.call or ins_decode_tmp.load;
exe_out <= ex_out_tmp;
instruction_decode_out <= ins_decode_tmp;
  
process (clk)
begin
if (clk'event and clk = '1') then
	if (ctrl.res = '1') then
	ex_out_tmp <= (others => '0');
		write_back_ex.d_valid <= '0';
	else
		write_back_ex.d_valid <= '0';
	if (instruction_decode_in.instr.valid ='1' and ctrl.stall = '0' ) then
		if (instruction_decode_in.alu = '1') then 						--alu operations
			ex_out_tmp <= alu_out;
		elsif (instruction_decode_in.loadi = '1') then 						--loadi instruction
			if(instruction_decode_in.instr.ir(26) = '0') then 
				ex_out_tmp <= operand_in.i & operand_a(15 downto 0);
			else
				ex_out_tmp <= operand_a(31 downto 16) & operand_in.i;
			end if;
		elsif (instruction_decode_in.load = '1') then 						--load instruction
			ex_out_tmp <=  std_logic_vector(signed (operand_a) + signed(signext)); -- address calculation of memory for load operation.
		elsif (instruction_decode_in.store = '1') then						--store instruction
			ex_out_tmp <=  std_logic_vector(signed (operand_a) + signed(signext));
		elsif(instruction_decode_in.call = '1' and instruction_decode_in.relative = '1')then 	-- BL instruction
			--ex_out_tmp <=  std_logic_vector(signed(instruction_decode_in.instr.pc)+ 4);--bl_temp;
			 write_back_ex.d  <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ 4);
			  ex_out_tmp <=  (others => '0');
			  write_back_ex.d_valid <= '1';
			   write_back_ex.idx_d <= instruction_decode_in.idx_d;
		elsif(instruction_decode_in.call = '1' and instruction_decode_in.relative = '0')then 	-- call instruction
			--ex_out_tmp <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ 4);--call_temp;
			  write_back_ex.d  <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ 4);
			  ex_out_tmp <=  (others => '0');
			  write_back_ex.d_valid <= '1';
			  write_back_ex.idx_d <= instruction_decode_in.idx_d;
		end if;
	end if;
	end if;
end if;
end process;


process(instruction_decode_in, signext_shift, operand_a)
begin

if (instruction_decode_in.instr.valid ='1' ) then
		call_temp <= (others => '0');
		bl_temp <= (others => '0');
	if (instruction_decode_in.jmp = '1' and instruction_decode_in.relative = '0') then 	-- JMP instruction
		branch_out_tmp.branch <= '1';
		branch_out.target <= operand_a;
	elsif (instruction_decode_in.jnz = '1' and instruction_decode_in.relative = '1')then 	--BNZ instruction
		if(operand_a /= x"00000000") then
			branch_out_tmp.branch <= '1';
			branch_out.target <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ signed(signext_shift));
		else
			branch_out_tmp.branch <= '0';
			branch_out.target <= x"00000000";
		end if; 
	elsif(instruction_decode_in.jz = '1' and instruction_decode_in.relative = '1')then 	-- BZ instruction
		if(operand_a = x"00000000") then
			branch_out_tmp.branch <= '1';
			branch_out.target <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ signed(signext_shift));
		else
			branch_out_tmp.branch <= '0';
			branch_out.target <= x"00000000";
		end if; 
	elsif (instruction_decode_in.jmp = '1' and instruction_decode_in.relative = '1') then 	-- BRA instruction
		branch_out_tmp.branch <= '1';
		branch_out.target <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ signed(signext_shift));
	elsif (instruction_decode_in.call = '1' and instruction_decode_in.relative = '1')then -- BL instruction
		branch_out_tmp.branch <= '1';
		branch_out.target <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ signed(signext_shift));
		bl_temp <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ 4);
	elsif (instruction_decode_in.call = '1' and instruction_decode_in.relative = '0')then 	-- call instruction
		branch_out_tmp.branch <= '1';
		branch_out.target <= operand_a;
		call_temp <= std_logic_vector(signed(instruction_decode_in.instr.pc)+ 4);
	else
		call_temp <= (others => '0');
		bl_temp <= (others => '0');
		branch_out_tmp.branch <= '0';
		branch_out.target <= (others => '0');
	end if;
else
	call_temp <= (others => '0');
	bl_temp <= (others => '0');
	branch_out_tmp.branch <= '0';
	branch_out.target <= (others => '0');
end if;
end process;

branch_out.branch <= branch_out_tmp.branch and branch_clear;
-------------
process (clk)	--branch signal will stay up only for 1 cycle
begin
if (clk'event and clk = '1') then
if (ctrl.res = '1') then
		branch_clear <= '1';
	else
		if branch_out_tmp.branch = '1' then
			branch_clear <= '0';
		else
			branch_clear <= '1';
		end if;
	end if;
end if;
end process; 

-------------



process (clk)
begin
if (clk'event and clk = '1') then
	if (ctrl.res = '1') then
		nop(ins_decode_tmp);
		store_data_out <= (others => '0');
	else
		if ctrl.stall = '0' then
			ins_decode_tmp <= instruction_decode_in;
			store_data_out <= operand_b; -- in case of store the content of reg D is stored in operand b.
		end if;
	end if;
end if;
end process; 

end behav;
