-- (3) Reference implementation (RefModule)
-- Reference Module: Rule 110 Cellular Automaton
-- 512-cell one-dimensional cellular automaton
-- Implements Rule 110 transition rules with synchronous load

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(511 downto 0);
    q    : out std_logic_vector(511 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(511 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
    variable left   : std_logic;
    variable center : std_logic;
    variable right  : std_logic;
    variable next_q : std_logic_vector(511 downto 0);
  begin
    if rising_edge(clk) then
      if load = '1' then
        q_reg <= data;
      else
        -- Compute next state for each cell
        -- Rule 110 implementation using bit-by-bit operations
        for i in 0 to 511 loop
          -- Get left neighbor (i+1), with boundary condition
          if i = 511 then
            left := '0';  -- Boundary: q[512] = 0
          else
            left := q_reg(i+1);
          end if;
          
          -- Get center (current cell)
          center := q_reg(i);
          
          -- Get right neighbor (i-1), with boundary condition
          if i = 0 then
            right := '0';  -- Boundary: q[-1] = 0
          else
            right := q_reg(i-1);
          end if;
          
          -- Rule 110: next = NOT((L AND C AND R) OR (NOT L AND NOT C AND NOT R) OR (L AND NOT C AND NOT R))
          next_q(i) := not ((left and center and right) or 
                           ((not left) and (not center) and (not right)) or
                           (left and (not center) and (not right)));
        end loop;
        
        q_reg <= next_q;
      end if;
    end if;
  end process;

end architecture rtl;