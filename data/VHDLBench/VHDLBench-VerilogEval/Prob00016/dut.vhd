-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-bit adder with 5-bit output (including overflow bit)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    x   : in  std_logic_vector(3 downto 0);
    y   : in  std_logic_vector(3 downto 0);
    sum : out std_logic_vector(4 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- 4-bit adder with overflow
  sum <= std_logic_vector(resize(unsigned(x), 5) + resize(unsigned(y), 5));

end architecture rtl;