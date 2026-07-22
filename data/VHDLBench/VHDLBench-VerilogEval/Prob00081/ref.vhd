-- (3) Reference implementation (RefModule)
-- Reference Module: 7458 Chip
-- Four AND gates and two OR gates
-- p1y = (p1a AND p1b AND p1c) OR (p1d AND p1e AND p1f)
-- p2y = (p2a AND p2b) OR (p2c AND p2d)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    p1a : in  std_logic;
    p1b : in  std_logic;
    p1c : in  std_logic;
    p1d : in  std_logic;
    p1e : in  std_logic;
    p1f : in  std_logic;
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
  
  -- Matches Verilog: assign p1y = &{p1a, p1b, p1c} | &{p1d, p1e, p1f};
  -- &{...} is reduction AND in Verilog
  p1y <= (p1a and p1b and p1c) or (p1d and p1e and p1f);
  
  -- Matches Verilog: assign p2y = &{p2a, p2b} | &{p2c, p2d};
  p2y <= (p2a and p2b) or (p2c and p2d);

end architecture rtl;