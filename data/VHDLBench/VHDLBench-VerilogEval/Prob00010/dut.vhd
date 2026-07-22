-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: z = (x^y) & x

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    x : in  std_logic;
    y : in  std_logic;
    z : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implement: z = (x XOR y) AND x
  z <= (x xor y) and x;

end architecture rtl;