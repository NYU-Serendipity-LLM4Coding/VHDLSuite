-- (3) Reference implementation (RefModule)
-- Reference Module: z = x | ~y
-- This is the expected output of the hierarchical circuit

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
  z <= x or (not y);
end architecture rtl;