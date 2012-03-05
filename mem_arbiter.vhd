library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
library work;
use work.types.all;

entity mem_arbiter is
  port(
        clk: in std_logic;
        res: in std_logic;
        port1_in, port2_in: in memory_in;
        port1_out, port2_out: out memory_out;
        mem_in: out memory_in;
        mem_out: in memory_out
      );
end entity;

architecture mem_arbiter_arch of mem_arbiter is
  type state_type is (default_access,port1_access,port2_access);
  signal state, next_state : state_type;
  signal port_sel: std_logic_vector (1 downto 0);
  begin
  
    port_sel(0) <= port1_in.enable;   -- enable signal of port 1
    port_sel(1) <= port2_in.enable;   -- enable signal of port 2.

    process(clk, res)                 -- sequential process of FSM
    begin
      if (clk'event and clk='1') then -- rising clock edge
        if(res ='1') then             -- synchronus reset
          state <= default_access;    -- starts with the default state
        else
          state <= next_state;        -- transition from current to next state
        end if;
      end if;
    end process;
  
    process(state, port_sel, mem_out)
    begin

      mem_in <= port1_in;
      next_state <= default_access;
      port1_out <= (data => X"00000000", rdy => '0');
      port2_out <= (data => X"00000000", rdy => '0');

      case state is

        when default_access =>
          case port_sel is
            when "01" =>                -- port 1 is enabled
              mem_in <= port1_in;       -- port 1 connected to mem_in
              port1_out <= mem_out;     -- mem output connected to port1 out
              next_state <= port1_access;

            when "10" =>                -- port 2 is enabled
              mem_in <= port2_in;       -- port 2 connected to mem_in
              port2_out <= mem_out;     -- mem output connected to port2 out              
              next_state <= port2_access;

            when "11" =>                
              mem_in <= port1_in;       -- port 1 connected to mem_in
              port1_out <= mem_out;     -- mem output connected to port1 out
              next_state <= port1_access;

            when OTHERS =>
              mem_in <= port1_in;       
              port1_out <= mem_out;
              next_state <= default_access;
          end case;

        when port1_access =>
          if (mem_out.rdy = '1') then   -- port 1 transaction is completed.
            mem_in <= port1_in;         -- port 1 connected to mem_in
            port1_out <= mem_out;       -- mem output connected to port1 out
            next_state <= default_access;  -- return to default state.
          else
            next_state <= port1_access;
            mem_in <= port1_in;         -- port 1 connected to mem_in
            port1_out <= mem_out;	-- mem output connected to port1 out
          end if;

        when port2_access =>
          if (mem_out.rdy = '1') then   -- port 2 transaction is completed.
            mem_in <= port2_in;         -- port 2 connected to mem_in
            port2_out <= mem_out;       -- mem output connected to port2 out
            next_state <= default_access;  -- return to default access state.
          else 
            next_state <= port2_access;
            mem_in <= port2_in;         -- port 2 connected to mem_in
            port2_out <= mem_out;       -- mem output connected to port2 out
          end if;
      end case;    

    end process;
  end mem_arbiter_arch;
