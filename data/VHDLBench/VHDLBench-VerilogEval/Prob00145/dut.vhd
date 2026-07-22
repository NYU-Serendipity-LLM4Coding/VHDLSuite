-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: q = D flip-flop (negedge), p = latch (transparent when clock high)

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clock : in  std_logic;
    a     : in  std_logic;
    p     : out std_logic;
    q     : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic;
begin

  q <= q_reg;

  -- q: Falling edge triggered flip-flop
  process(clock)
  begin
    if falling_edge(clock) then
      q_reg <= a;
    end if;
  end process;

  -- p: Latch (transparent when clock is high)
  process(clock, a)
  begin
    if clock = '1' then
      p <= a;
    end if;
  end process;

end architecture rtl;