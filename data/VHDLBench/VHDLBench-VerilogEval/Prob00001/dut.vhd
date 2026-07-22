-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Always output LOW (0)

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    zero : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  zero <= '0';

end architecture rtl;