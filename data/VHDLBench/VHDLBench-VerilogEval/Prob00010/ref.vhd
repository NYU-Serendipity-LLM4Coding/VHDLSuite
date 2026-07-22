-- (3) Reference implementation (RefModule)
-- Reference Module: Boolean function z = (x^y) & x
-- Implements: z = (x XOR y) AND x

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
  
  -- Matches Verilog: assign z = (x^y) & x;
  z <= (x xor y) and x;

end architecture rtl;