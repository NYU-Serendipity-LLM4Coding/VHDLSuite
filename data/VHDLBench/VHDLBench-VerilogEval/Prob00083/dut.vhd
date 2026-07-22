-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement XNOR gate: z = NOT(x XOR y)

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
  
  -- Implement XNOR: z = NOT(x XOR y)
  z <= not (x xor y);

end architecture rtl;