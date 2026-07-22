-- (3) Reference implementation (RefModule)
-- Reference Module: 7420 Dual 4-input NAND Gate
-- Implements two independent 4-input NAND gates
-- p1y = NAND(p1a, p1b, p1c, p1d)
-- p2y = NAND(p2a, p2b, p2c, p2d)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    p1a : in  std_logic;
    p1b : in  std_logic;
    p1c : in  std_logic;
    p1d : in  std_logic;
    p1y : out std_logic;
    p2a : in  std_logic;
    p2b : in  std_logic;
    p2c : in  std_logic;
    p2d : in  std_logic;
    p2y : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign p1y = ~&({p1a, p1b, p1c, p1d});
  -- NAND of all inputs: NOT (p1a AND p1b AND p1c AND p1d)
  p1y <= not (p1a and p1b and p1c and p1d);
  
  -- Matches Verilog: assign p2y = ~&({p2a, p2b, p2c, p2d});
  p2y <= not (p2a and p2b and p2c and p2d);

end architecture rtl;