-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement next-state logic for Y1 and Y3

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    y  : in  std_logic_vector(5 downto 0);
    w  : in  std_logic;
    Y1 : out std_logic;
    Y3 : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Next-state logic for Y1 (state flip-flop y[1])
  -- Y1 = y[0] AND w (A->B transition when w=1)
  Y1 <= y(0) and w;
  
  -- Next-state logic for Y3 (state flip-flop y[3])
  -- Y3 = (y[1] OR y[2] OR y[4] OR y[5]) AND NOT w
  -- (B,C,E,F -> D transitions when w=0)
  Y3 <= (y(1) or y(2) or y(4) or y(5)) and (not w);

end architecture rtl;