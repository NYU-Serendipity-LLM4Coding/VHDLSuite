-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Positive edge-triggered D flip-flop

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic := 'U';
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      q_reg <= d;
    end if;
  end process;

end architecture rtl;