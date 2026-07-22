-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement AND gate using two methods

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a               : in  std_logic;
    b               : in  std_logic;
    out_assign      : out std_logic;
    out_alwaysblock : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Method 1: Concurrent assignment
  out_assign <= a and b;
  
  -- Method 2: Combinational process
  process(a, b)
  begin
    out_alwaysblock <= a and b;
  end process;

end architecture rtl;