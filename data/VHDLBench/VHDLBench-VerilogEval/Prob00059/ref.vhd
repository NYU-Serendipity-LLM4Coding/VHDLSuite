-- (3) Reference implementation (RefModule)
-- Reference Module: Wire Connections
-- Implements simple wire routing: a->w, b->x, b->y, c->z
-- Matches Verilog: assign {w,x,y,z} = {a,b,b,c};

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    c : in  std_logic;
    w : out std_logic;
    x : out std_logic;
    y : out std_logic;
    z : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign {w,x,y,z} = {a,b,b,c};
  w <= a;
  x <= b;
  y <= b;
  z <= c;

end architecture rtl;