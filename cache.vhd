library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
library work;
use work.types.all;

entity instruction_cache is
  generic (
  LINE_ADR : natural := 4; --no of bits for line addr
  BLOCK_ADR : natural := 4 -- no of bits for block addr for each line.
  );
  
  port (
    clk : in std_logic;
    res : in std_logic;
    
    cpu_from : in memory_in;
    cpu_to   : out memory_out;
    memory_to   : out memory_in;
    memory_from : in memory_out
  );
end entity;

architecture behav of instruction_cache is

--ram signals
  type ram_type is array(0 to 255) of std_logic_vector(31 downto 0); -- infereing ram block
  signal ram : ram_type := (others =>(others => '0'));-- clearing for simulation purpose.

--cache signals
  signal cache_hit : std_logic;
  
  subtype cache_tag is std_logic_vector(21 downto 0);
  subtype cacheline_valid is std_logic;
  type cacheline_ctrl is record
	tag : cache_tag;
	valid : cacheline_valid;
  end record cacheline_ctrl;
  type cacheline_vector_type is array(0 to 15) of cacheline_ctrl;
  signal cacheline_ctrl_vector : cacheline_vector_type; -- array of line control (tag and valids)

--state signals
  type state_type is (idle, enable, wait_rdy ); -- state used for reading of data from memory.
  signal state, next_state : state_type;

--addr signals
  signal data_tag : std_logic_vector(21 downto 0); -- hold the tag information from the cpu addr bus.
  signal cacheline_addr : std_logic_vector(3 downto 0);
  signal ram_addr : std_logic_vector(7 downto 0); -- holds ram addr from the cpu addr bus.

  signal linecount: std_logic_vector((BLOCK_ADR - 1) downto 0); 
  signal partlr_cacheline_addr : std_logic_vector (31 downto 0); --hold the addr of the words of a partlr line.
  signal partlr_cacheline_addr_tag : std_logic_vector (21 downto 0); 

  signal starting_cacheline_addr : std_logic_vector (25 downto 0);-- addr till the start of the line.
  signal readall_flag : std_logic;
  signal reglatch_line_read : std_logic_vector (3 downto 0); -- register to latch line addr.
  
  
  
begin
  data_tag <= cpu_from.adr(31 downto 10);
  cacheline_addr <= cpu_from.adr(9 downto 6);  
  ram_addr <= cpu_from.adr(9 downto 2);
  starting_cacheline_addr <= cpu_from.adr(31 downto 6); -- addr till the start of the line.

  process (clk)
  begin
   if (clk'event and clk = '1') then
     if (res = '1') then   -- when reset clear all the cache ctrl registers.
	cacheline_ctrl_vector(0).valid <= '0'; cacheline_ctrl_vector(0).tag <= (others => '0');
	cacheline_ctrl_vector(1).valid <= '0'; cacheline_ctrl_vector(1).tag <= (others => '0');
	cacheline_ctrl_vector(2).valid <= '0'; cacheline_ctrl_vector(2).tag <= (others => '0');
	cacheline_ctrl_vector(3).valid <= '0'; cacheline_ctrl_vector(3).tag <= (others => '0');
	cacheline_ctrl_vector(4).valid <= '0'; cacheline_ctrl_vector(4).tag <= (others => '0');
	cacheline_ctrl_vector(5).valid <= '0'; cacheline_ctrl_vector(5).tag <= (others => '0');
	cacheline_ctrl_vector(6).valid <= '0'; cacheline_ctrl_vector(6).tag <= (others => '0');
	cacheline_ctrl_vector(7).valid <= '0'; cacheline_ctrl_vector(7).tag <= (others => '0');
	cacheline_ctrl_vector(8).valid <= '0'; cacheline_ctrl_vector(8).tag <= (others => '0');
	cacheline_ctrl_vector(9).valid <= '0'; cacheline_ctrl_vector(9).tag <= (others => '0');
	cacheline_ctrl_vector(10).valid <= '0'; cacheline_ctrl_vector(10).tag <= (others => '0');
	cacheline_ctrl_vector(11).valid <= '0'; cacheline_ctrl_vector(11).tag <= (others => '0');
	cacheline_ctrl_vector(12).valid <= '0'; cacheline_ctrl_vector(12).tag <= (others => '0');
	cacheline_ctrl_vector(13).valid <= '0'; cacheline_ctrl_vector(13).tag <= (others => '0');
	cacheline_ctrl_vector(14).valid <= '0'; cacheline_ctrl_vector(14).tag <= (others => '0');
	cacheline_ctrl_vector(15).valid <= '0'; cacheline_ctrl_vector(15).tag <= (others => '0');

	partlr_cacheline_addr_tag <= (others => '0');
	partlr_cacheline_addr <= (others => '0');
	state <= idle;
	linecount <=(others => '0');
	readall_flag <= '0';
  
     else
	cpu_to.data <= (others => '0');
	cpu_to.rdy <= '0';
	memory_to.adr <= (others => '0');
	memory_to.we <= '0';
	memory_to.enable <= '0';
	memory_to.data <= (others => '0'); 
       
	case state is 
	
		when idle =>
		if (cpu_from.we = '0' and cpu_from.enable = '1') then
			cpu_to.rdy <= '0';
			if (cache_hit = '1' and readall_flag = '1') then
				cpu_to.data <= ram(to_integer(unsigned(cpu_from.adr(9 downto 2))));
				cpu_to.rdy <= '1';
				state <= idle;
			else  -- cache miss
				state <= enable;
				linecount <= "1111"; -- counts the number of words in the line.
				readall_flag <= '0'; 
				partlr_cacheline_addr <= starting_cacheline_addr & "000000"; -- starting of the line.
				partlr_cacheline_addr_tag <= starting_cacheline_addr(25 downto 4);
				reglatch_line_read <= starting_cacheline_addr(3 downto 0);
			end if;
		end if;

		when enable =>
			memory_to.enable <= '1';
			memory_to.adr <= partlr_cacheline_addr;
			state <= wait_rdy;
			cpu_to.rdy <= '0';
		 
		when wait_rdy =>
		cpu_to.rdy <= '0';
		if (memory_from.rdy = '1') then
			ram(to_integer(unsigned(partlr_cacheline_addr(9 downto 2)))) <= memory_from.data; -- writing the read data into cache.
			if (partlr_cacheline_addr = cpu_from.adr and cpu_from.enable = '1' ) then  -- the word requested from cpu
				cpu_to.data <=  memory_from.data;
				cpu_to.rdy <= '1';
			end if;
			partlr_cacheline_addr <= std_logic_vector (unsigned (partlr_cacheline_addr) + 4);  
			if (linecount = "0000") then
				if (readall_flag = '1') then
					state <= idle;
					readall_flag <= '0'; 
					cacheline_ctrl_vector(to_integer(unsigned(reglatch_line_read(3 downto 0)))).tag <= partlr_cacheline_addr_tag ;
					cacheline_ctrl_vector(to_integer(unsigned(reglatch_line_read(3 downto 0)))).valid <= '1';
				else
					state <= enable;
					readall_flag <= '1';
					cacheline_ctrl_vector(0).valid <= '0';
					cacheline_ctrl_vector(1).valid <= '0';
					cacheline_ctrl_vector(2).valid <= '0';
					cacheline_ctrl_vector(3).valid <= '0';
					cacheline_ctrl_vector(4).valid <= '0';
					cacheline_ctrl_vector(5).valid <= '0';
					cacheline_ctrl_vector(6).valid <= '0';
					cacheline_ctrl_vector(7).valid <= '0';
					cacheline_ctrl_vector(8).valid <= '0';
					cacheline_ctrl_vector(9).valid <= '0';
					cacheline_ctrl_vector(10).valid <= '0';
					cacheline_ctrl_vector(11).valid <= '0';
					cacheline_ctrl_vector(12).valid <= '0';
					cacheline_ctrl_vector(13).valid <= '0';
					cacheline_ctrl_vector(14).valid <= '0';
					cacheline_ctrl_vector(15).valid <= '0';

				end if;
			else
				state <= enable;
				linecount <= std_logic_vector(unsigned (linecount) - 1);
			end if;      
		else
			memory_to.enable <= '1';
			memory_to.adr <= partlr_cacheline_addr;
			state <= wait_rdy;
		end if;
			  
		end case;   
     end if;
   end if;
  end process;

  
  process (cpu_from.we, cpu_from.enable, cpu_from.adr, cacheline_addr, data_tag)
  begin
	cache_hit <= '0';
    if (cpu_from.we = '0' and cpu_from.enable = '1') then
	cache_hit <= '0';
      case TO_INTEGER(UNSIGNED(cacheline_addr)) is -- line addr
        when 0 =>
          if ((cacheline_ctrl_vector(0).valid = '1') and (cacheline_ctrl_vector(0).tag = data_tag)) then -- check for valid bit and tag addr.
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
        when 1 =>
          if (cacheline_ctrl_vector(1).valid = '1' and cacheline_ctrl_vector(1).tag = data_tag) then
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 2 =>
          if (cacheline_ctrl_vector(2).valid = '1' and cacheline_ctrl_vector(2).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 3 =>
          if (cacheline_ctrl_vector(3).valid = '1' and cacheline_ctrl_vector(3).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 4 =>
          if (cacheline_ctrl_vector(4).valid = '1' and cacheline_ctrl_vector(4).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 5 =>
          if (cacheline_ctrl_vector(5).valid = '1' and cacheline_ctrl_vector(5).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
        when 6 =>
          if (cacheline_ctrl_vector(6).valid = '1' and cacheline_ctrl_vector(6).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
        when 7 =>
          if (cacheline_ctrl_vector(7).valid = '1' and cacheline_ctrl_vector(7).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 8 =>
          if (cacheline_ctrl_vector(8).valid = '1' and cacheline_ctrl_vector(8).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 9 =>
          if (cacheline_ctrl_vector(9).valid = '1' and cacheline_ctrl_vector(9).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 10 =>
          if (cacheline_ctrl_vector(10).valid = '1' and cacheline_ctrl_vector(10).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 11 =>
          if (cacheline_ctrl_vector(11).valid = '1' and cacheline_ctrl_vector(11).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
        when 12 =>
          if (cacheline_ctrl_vector(12).valid = '1' and cacheline_ctrl_vector(12).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
        when 13 =>
          if (cacheline_ctrl_vector(13).valid = '1' and cacheline_ctrl_vector(13).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 14 =>
          if (cacheline_ctrl_vector(14).valid = '1' and cacheline_ctrl_vector(14).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when 15 =>
          if (cacheline_ctrl_vector(15).valid = '1' and cacheline_ctrl_vector(15).tag = data_tag) then 
            cache_hit <= '1';
          else 
            cache_hit <= '0';
          end if;
         when others =>
          cache_hit <= '0';
     end case;
    end if;
  end process;



end behav;
