-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Half Adder (sum and carry-out)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    sum  : out std_logic;
    cout : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal result : unsigned(1 downto 0);
begin
  
  -- Half adder implementation
  result <= resize(unsigned'(0 => a), 2) + resize(unsigned'(0 => b), 2);
  
  sum  <= result(0);
  cout <= result(1);

end architecture rtl;