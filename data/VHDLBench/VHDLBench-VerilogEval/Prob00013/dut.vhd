-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 2-input NOR gate

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    in1        : in  std_logic;
    in2        : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  signal_out <= not (in1 or in2);

end architecture rtl;