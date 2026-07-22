-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: vector passthrough and bit splitting

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    vec  : in  std_logic_vector(2 downto 0);
    outv : out std_logic_vector(2 downto 0);
    o2   : out std_logic;
    o1   : out std_logic;
    o0   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Pass through the vector
  outv <= vec;
  
  -- Split vector into individual bits
  o2 <= vec(2);
  o1 <= vec(1);
  o0 <= vec(0);

end architecture rtl;