library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.uniform;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

package types is
  subtype Rregs is natural range 31 downto 0;
  subtype Radr is natural range 31 downto 0;
  subtype Tadr is std_logic_vector(Radr);
  subtype Rdata is natural range 31 downto 0;
  subtype Tdata is std_logic_vector(Rdata);
  subtype Rimmediate is natural range 15 downto 0;
  subtype Timmediate is std_logic_vector(Rimmediate);
  
  subtype Ridx_a is natural range 20 downto 16;
  subtype Ridx_b is natural range 15 downto 11;
  subtype Ridx_d is natural range 25 downto 21;
  subtype Tidx is std_logic_vector(4 downto 0);

  type control is record
    res    : std_logic;
    stall  : std_logic;
  end record control;
  type branch is record
    branch : std_logic;
    target : Tadr;
  end record branch;
  type write_back is record
    d     : Tdata;
    d_valid:std_logic;
    idx_d : Tidx;
  end record write_back;
  type operand_type is record
    a     : Tdata;
    b     : Tdata;
    i     : Timmediate;
  end record operand_type;
  type instruction is record
    pc : Tadr;
    ir  : Tdata;
    valid  : std_logic;
  end record instruction;
  type instruction_decoded is record
    instr : instruction;
    idx_a, idx_b, idx_d : Tidx;
    load,loadi,store,alu : std_logic;
    jmp,jz,jnz,call,relative,rfe : std_logic;
    alu_op : std_logic_vector(3 downto 0);
  end record instruction_decoded;
  procedure nop(signal instr : out instruction_decoded);
  type memory_in is record
    adr: Tadr;
    we : std_logic;
    enable : std_logic;
    data : Tdata;
  end record memory_in;
  type memory_out is record
    data: Tdata;
    rdy: std_logic;
  end record memory_out;
  type sul_bool is array(boolean) of std_ulogic;
  constant active_high: sul_bool := (
      FALSE => '0' ,
      TRUE  => '1' ); 
end package types;

package body types is
  procedure nop(signal instr : out instruction_decoded) is
  begin
    instr.instr.valid <= '0';
    instr.load <= '0';
    instr.loadi <= '0'; 
    instr.store <= '0';
    instr.alu <= '0';
    instr.jmp <= '0';
    instr.jz <= '0';
    instr.jnz <= '0';
    instr.relative <= '0';
    instr.call <= '0';
    instr.rfe <= '0';
  end procedure nop;
end package body types;
