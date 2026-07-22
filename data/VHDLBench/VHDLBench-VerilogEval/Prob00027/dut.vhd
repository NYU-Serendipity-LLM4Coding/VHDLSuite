-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Full Adder (sum and carry-out)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    cin  : in  std_logic;
    cout : out std_logic;
    sum  : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal result : unsigned(1 downto 0);
begin
  
  -- Full adder implementation
  result <= resize(unsigned'(0 => a), 2) + 
            resize(unsigned'(0 => b), 2) + 
            resize(unsigned'(0 => cin), 2);
  
  cout <= result(1);
  sum  <= result(0);

end architecture rtl;