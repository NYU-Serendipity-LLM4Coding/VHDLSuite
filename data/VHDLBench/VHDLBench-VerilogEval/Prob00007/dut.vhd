-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Wire (output follows input)

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  signal_out <= signal_in;
end architecture rtl;