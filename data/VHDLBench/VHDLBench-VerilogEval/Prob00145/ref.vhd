-- (3) Reference implementation (RefModule)
-- Reference Module: Sequential Circuit with Latch and Flip-Flop
-- q: D flip-flop triggered on falling edge of clock
-- p: Transparent latch (follows 'a' when clock is high)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clock : in  std_logic;
    a     : in  std_logic;
    p     : out std_logic;
    q     : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic;
begin

  q <= q_reg;

  -- Matches Verilog: always @(negedge clock) q <= a;
  process(clock)
  begin
    if falling_edge(clock) then
      q_reg <= a;
    end if;
  end process;

  -- Matches Verilog: always @(*) if (clock) p = a;
  -- This is a latch: p follows a when clock is high
  process(clock, a)
  begin
    if clock = '1' then
      p <= a;
    end if;
  end process;

end architecture rtl;