-- (3) Reference implementation (RefModule)
-- Reference Module: XNOR Gate
-- Implements z = NOT(x XOR y) = x XNOR y
-- Truth table: z=1 when x==y, z=0 when x!=y

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    x : in  std_logic;
    y : in  std_logic;
    z : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign z = ~(x^y);
  z <= not (x xor y);

end architecture rtl;