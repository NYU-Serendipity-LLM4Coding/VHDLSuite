-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement wire connections: a->w, b->x, b->y, c->z

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    c : in  std_logic;
    w : out std_logic;
    x : out std_logic;
    y : out std_logic;
    z : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  w <= a;
  x <= b;
  y <= b;
  z <= c;

end architecture rtl;