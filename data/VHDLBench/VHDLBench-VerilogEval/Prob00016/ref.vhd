-- (3) Reference implementation (RefModule)
-- Reference Module: 4-bit Adder with Overflow
-- Computes sum = x + y with 5-bit output (includes carry/overflow bit)
-- Matches Verilog: assign sum = x+y;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    x   : in  std_logic_vector(3 downto 0);
    y   : in  std_logic_vector(3 downto 0);
    sum : out std_logic_vector(4 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign sum = x+y;
  -- Convert to unsigned, add, then convert back to std_logic_vector
  -- The addition automatically extends to 5 bits to capture overflow
  sum <= std_logic_vector(resize(unsigned(x), 5) + resize(unsigned(y), 5));

end architecture rtl;