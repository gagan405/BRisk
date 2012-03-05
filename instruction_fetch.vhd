library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use work.types.all;

entity instr_fetch is
  port (
    clk         :       in std_logic;
    ctrl        :       in control;
    stall_req   :       out std_logic;
    brn         :       in  branch;
    ins         :       out instruction;
    req_mem     :       out memory_in;
    rd_mem      :       in  memory_out
    );
  
end instr_fetch;

architecture behav_ifetch of instr_fetch is

  signal PC, nxtPC : Tadr ;    -- program counter
  signal PC_bak : Tadr ;
  signal instr : instruction;           -- output register for instruction
  signal flag_mem_req, stalledPC : std_logic;
  signal temp_instr : instruction;      -- temporary instruction register for stalled cycles
  signal stalled_instruction, enable : std_logic;  -- flag to indicate if the instruction is to be retrieved from the temporary registers
--  signal ignore_next_ins : std_logic;
  signal instr_req : memory_in;
  signal sel : std_logic_vector(1 downto 0);
  signal branch : Tadr;
begin  -- behav_ifetch

  -- purpose: fetch instruction
  -- type   : sequential
  -- inputs : clk, res, mem_in
  -- outputs: ir, mem_out
  -----------------------------------------------------------------------------
  -- 1. Get the next PC
  -- 2. Request for instruction from memory
  -----------------------------------------------------------------------------
  
  -- purpose: Takes care of the Program counter
  -- inputs : clk

counter: process (clk)
begin  -- process counter    
  if clk'event and clk = '1' then    -- rising clock edge
    if ctrl.res = '1' then
      PC <= (others => '0');
      enable <= '1';
      PC_bak <= (others => '0');	
      stalledPC <= '0';	
    else
      if ctrl.stall = '1' then

        if rd_mem.rdy = '1' then
          PC <= nxtPC;
          enable <= '0';
          
        end if;
      else
        if brn.branch = '1' then
          PC <= brn.target;
          enable <= '1';
        elsif  rd_mem.rdy = '1' then
          PC <= nxtPC;
          enable <= '1';
        elsif stalled_instruction = '1' then
          enable <= '1';
        end if; 
      end if;
    end if;
  end if;
end process counter;

process (PC, brn)
begin  -- process 
  if brn.branch = '1' then
    nxtPC <= Tadr(unsigned(brn.target)+4);
  else    
    nxtPC <= Tadr(unsigned(PC)+4);
  end if;
 
end process;

  
-- purpose: Read instruction when ready
-- type   : sequential
-- inputs : clk

read: process (clk)
begin  -- process read
  if clk'event and clk = '1' then
    if ctrl.res = '1' then
      temp_instr.pc <= (others => '0');      --reset the output and temporary registers
      temp_instr.ir <= (others => '0');
      temp_instr.valid <= '0';
      instr.pc <= (others => '0');      --reset the output and temporary registers
      instr.ir <= (others => '0');
      instr.valid <= '0';
      stalled_instruction <= '0';
      flag_mem_req <= '1';	
    else
    
      if rd_mem.rdy = '1' and flag_mem_req = '1' then
        if ctrl.stall = '0' then
          instr.pc <= PC;          
          instr.ir <= rd_mem.data;
          instr.valid <= '1';
	  flag_mem_req <= '1';
        else
          temp_instr.pc <= PC;          
          temp_instr.ir <= rd_mem.data;
          stalled_instruction <= '1';
          temp_instr.valid <= '1';
	  flag_mem_req <= '0';
        end if;	
      end if;
      if stalled_instruction = '1' and ctrl.stall = '0' then 
        instr <= temp_instr;
        stalled_instruction <= '0';
        flag_mem_req <= '1';
      end if;
      
    end if;
  end if;
end process read;

process(brn,PC)
begin  -- process
  if brn.branch = '1' then
    req_mem.adr <= brn.target;
  else
    req_mem.adr <= PC;
  end if;
end process;


req_mem.enable <= enable;-- and (not ctrl.stall);
req_mem.we <= '0';
req_mem.data <= (others => '0');
ins <= instr;
stall_req <= not rd_mem.rdy and (not stalled_instruction);-- or ctrl.stall;-- and enable;

end behav_ifetch;
