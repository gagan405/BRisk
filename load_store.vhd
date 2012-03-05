library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use work.types.all;

entity load_store_unit is
  port (
-- control inputs
    clk         :       in std_logic;
    ctrl        :       in control;

-- outputs 
    stall_req   :       out std_logic;
    wb          :       out write_back;

-- memory access ports
    to_memory   :       out memory_in;
    from_memory :       in  memory_out;

-- from the Execution unit
    ins_decoded :       in instruction_decoded;
    data        :       in Tdata;
    addr        :       in Tadr
  );
  
end load_store_unit;

architecture behav_ld_store of load_store_unit is
signal sel : std_logic_vector(1 downto 0);
signal temp_wb : write_back;            -- temporary storage for stalled cycles
signal stalled : std_logic;             -- flag to indicate that we have a stall
signal req_memory : memory_in;
--signal mem_info : memory_in;
signal reg_info : write_back;           -- no comments
signal flag_mem_req, global_stall : std_logic;
signal wb_enable, valid_bit : std_logic;
signal stall, ack, ldst : std_logic;
signal reg_idx : Tidx;
begin  -- behav_ld_store


  reg_info.d <= addr;                   -- If it is not a store ins, then it
                                        -- contains the data
  reg_info.d_valid <= '0';
  reg_info.idx_d <= ins_decoded.idx_d;
  sel <= ctrl.stall & req_memory.enable;
  wb_enable <= ins_decoded.loadi or ins_decoded.alu;-- or ins_decoded.call;

-- purpose: drive output registers
-- type   : sequential
-- inputs : clk
-- outputs: 
output_registers: process (clk)
--  variable sel : std_logic_vector(1 downto 0);

begin  -- process output_registers
  if clk'event and clk = '1' then    -- rising clock edge

--    sel := ctrl.stall & mem_info.enable;
    
    if ctrl.res = '1' then
      wb.d <= (others => '0');
      wb.d_valid <= '0';
      wb.idx_d <= (others => '0');
    else
      case sel is
        when "00" =>                    -- Writeback (no load/store)
          if wb_enable = '1' then
            wb <= reg_info;
            wb.d_valid <= '1';
          else
		if global_stall = '0' then
            		wb.d_valid <= '0';
		end if;
          end if;
        when "01" =>                    -- Load/store
          if from_memory.rdy = '1' then
            wb.d <= from_memory.data;
            wb.d_valid <= valid_bit;--not req_memory.we;
            --wb.idx_d <= reg_info.idx_d;
	    wb.idx_d <= reg_idx;
	  else
	    	if global_stall = '0' then
            		wb.d_valid <= '0';
		end if;
          end if;
        when "10" =>                    -- writeback, but we have a stall
          if wb_enable = '1' then
            temp_wb <= reg_info;
            stalled <= '1';
            temp_wb.d_valid <= '1';
          else
	    if ldst = '1' then
		temp_wb.d_valid <= valid_bit;
	    else
             temp_wb.d_valid <= '0';
	    end if;	
          end if;
        when "11" =>                    -- load/store, but we have a stall
          if from_memory.rdy = '1' then  
            temp_wb.d <= from_memory.data;
            temp_wb.d_valid <= valid_bit;--not req_memory.we;
            --temp_wb.idx_d <= reg_info.idx_d;
	    temp_wb.idx_d <= reg_idx;
            stalled <= '1';
	    ldst <= '1' ;
          end if;
        when others => null;
      end case;

      if stalled = '1' and ctrl.stall = '0' then
        wb <= temp_wb;
        stalled <= '0';
	ldst <= '0' ;
      end if;    
    end if;    
  end if;
end process output_registers;

request_mem: process (clk)
begin  -- process request_mem
if clk'event and clk = '1' then
  if ctrl.res = '1' then
    req_memory.adr <= (others => '0');
    req_memory.data <= (others => '0');
    req_memory.we <= '0';
    req_memory.enable <= '0';
    flag_mem_req <= '0';
    stall <= '0';
    ack <= '0';
    valid_bit <= '0';	
  else
    -- request data from memory (load/store)
    if from_memory.rdy = '0' and flag_mem_req = '0' then  -- and ctrl.stall = '0'
	if (ins_decoded.load or ins_decoded.store) = '1' then
	      req_memory.adr <= addr;        
      	      req_memory.data <= data;
      	      req_memory.we <= ins_decoded.store;
              req_memory.enable <= (ins_decoded.load or ins_decoded.store);
              flag_mem_req <= '1';
	      reg_idx <= ins_decoded.idx_d;	
	      valid_bit <= ins_decoded.load;	
	      stall <= '1';	
	end if;
   elsif from_memory.rdy = '1' and flag_mem_req = '1' then
                                        -- send low acknowledgment
              req_memory.adr <=  (others => '0');        
	      req_memory.data <= (others => '0');
              req_memory.we <= '0';
              req_memory.enable <= '0';
              flag_mem_req <= '0';
              ack <= '1';
   end if;
   
  if ack = '1' then stall <= '0'; ack <= '0'; end if;
 end if;
if valid_bit = '1' and ctrl.stall = '0' and ins_decoded.load = '0' then
 valid_bit <= '0'; 
end if;

end if;
end process request_mem;

global_stall <= (not ack) or ((req_memory.enable) and (not from_memory.rdy)) or ctrl.stall;
to_memory <= req_memory;
--stall_req <= (not ack) or ((req_memory.enable) and (not from_memory.rdy));
stall_req <= (flag_mem_req and (not from_memory.rdy)) or stall;

end behav_ld_store;



