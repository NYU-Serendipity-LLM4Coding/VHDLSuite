-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: constant output of '1'

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    one_output : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  -- Drive output to constant '1'
  one_output <= '1';
end architecture rtl;