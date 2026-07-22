-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: output always drives '0'

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  signal_out <= '0';

end architecture rtl;