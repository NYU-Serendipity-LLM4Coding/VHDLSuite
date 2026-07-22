-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 2-bit equality comparator
-- Output z = 1 when A = B, otherwise z = 0

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    A : in  std_logic_vector(1 downto 0);
    B : in  std_logic_vector(1 downto 0);
    z : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  z <= '1' when (A = B) else '0';

end architecture rtl;