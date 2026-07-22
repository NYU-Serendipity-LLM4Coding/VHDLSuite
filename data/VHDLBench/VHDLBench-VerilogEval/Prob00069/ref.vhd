-- (3) Reference implementation (RefModule)
-- Reference Module: Truth Table Implementation
-- Combinational logic implementing the specified truth table
-- f = (~x3 & x2 & ~x1) | (~x3 & x2 & x1) | (x3 & ~x2 & x1) | (x3 & x2 & x1)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    x3 : in  std_logic;
    x2 : in  std_logic;
    x1 : in  std_logic;
    f  : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign f = (~x3 & x2 & ~x1) | (~x3 & x2 & x1) | 
  --                              (x3 & ~x2 & x1) | (x3 & x2 & x1);
  f <= ((not x3) and x2 and (not x1)) or
       ((not x3) and x2 and x1) or
       (x3 and (not x2) and x1) or
       (x3 and x2 and x1);

end architecture rtl;