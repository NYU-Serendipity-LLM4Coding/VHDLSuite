-- (3) Reference implementation (RefModule)
-- Reference Module: Half Adder
-- Adds two bits (a + b) producing sum and carry-out
-- Matches Verilog: assign {cout, sum} = a+b;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    sum  : out std_logic;
    cout : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal result : unsigned(1 downto 0);
begin
  
  -- Perform addition: {cout, sum} = a + b
  -- Convert single bits to unsigned(1 downto 0) for addition
  result <= resize(unsigned'(0 => a), 2) + resize(unsigned'(0 => b), 2);
  
  -- Extract sum (LSB) and cout (MSB)
  sum  <= result(0);
  cout <= result(1);

end architecture rtl;