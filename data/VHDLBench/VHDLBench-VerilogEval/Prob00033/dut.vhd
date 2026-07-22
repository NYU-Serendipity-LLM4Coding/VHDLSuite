-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit signed adder with overflow detection

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    a        : in  std_logic_vector(7 downto 0);
    b        : in  std_logic_vector(7 downto 0);
    s        : out std_logic_vector(7 downto 0);
    overflow : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal sum : std_logic_vector(8 downto 0);
begin
  
  -- 9-bit addition
  sum <= std_logic_vector(resize(unsigned(a), 9) + resize(unsigned(b), 9));
  
  -- Extract lower 8 bits
  s <= sum(7 downto 0);
  
  -- Overflow detection
  overflow <= (not (a(7) xor b(7))) and (a(7) xor sum(7));

end architecture rtl;