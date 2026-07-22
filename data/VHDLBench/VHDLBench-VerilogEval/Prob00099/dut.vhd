-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement next-state logic for Y2 and Y4

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    y  : in  std_logic_vector(6 downto 1);
    w  : in  std_logic;
    Y2 : out std_logic;
    Y4 : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Next state Y2 (state B): active when in state A (y[1]=1) and w=0
  Y2 <= y(1) and (not w);
  
  -- Next state Y4 (state D): active when in states B,C,E,F and w=1
  Y4 <= (y(2) or y(3) or y(5) or y(6)) and w;

end architecture rtl;