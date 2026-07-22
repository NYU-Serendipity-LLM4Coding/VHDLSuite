-- (3) Reference implementation (RefModule)
-- Reference Module: AND Gate
-- Implements q = a AND b
-- Translated from Verilog to VHDL 2008

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    q : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign q = a&b;
  q <= a and b;

end architecture rtl;