-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Rule 110 Cellular Automaton

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(511 downto 0);
    q    : out std_logic_vector(511 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
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
        for i in 0 to 511 loop
          -- Get left neighbor (i+1), boundary = 0
          if i = 511 then
            left := '0';
          else
            left := q_reg(i+1);
          end if;
          
          -- Current cell
          center := q_reg(i);
          
          -- Get right neighbor (i-1), boundary = 0
          if i = 0 then
            right := '0';
          else
            right := q_reg(i-1);
          end if;
          
          -- Rule 110 transition
          next_q(i) := not ((left and center and right) or 
                           ((not left) and (not center) and (not right)) or
                           (left and (not center) and (not right)));
        end loop;
        
        q_reg <= next_q;
      end if;
    end if;
  end process;

end architecture rtl;