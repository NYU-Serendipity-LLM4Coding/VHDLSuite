-- (3) Reference implementation (RefModule)
-- Reference Module: Full Adder
-- Computes sum and carry-out from three input bits
-- Matches Verilog: assign {cout, sum} = a+b+cin;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    cin  : in  std_logic;
    cout : out std_logic;
    sum  : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal result : unsigned(1 downto 0);
begin
  
  -- Matches Verilog: assign {cout, sum} = a+b+cin;
  -- Convert single bits to unsigned, add them, then split result
  result <= resize(unsigned'(0 => a), 2) + 
            resize(unsigned'(0 => b), 2) + 
            resize(unsigned'(0 => cin), 2);
  
  cout <= result(1);
  sum  <= result(0);

end architecture rtl;