-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Decade counter (1 to 10) with synchronous reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : unsigned(3 downto 0) := to_unsigned(1, 4);
begin
  
  q <= std_logic_vector(q_reg);
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or q_reg = 10 then
        q_reg <= to_unsigned(1, 4);
      else
        q_reg <= q_reg + 1;
      end if;
    end if;
  end process;

end architecture rtl;