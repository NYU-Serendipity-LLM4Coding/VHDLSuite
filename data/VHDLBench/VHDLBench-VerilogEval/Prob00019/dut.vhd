-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: AND gate with inverted second input (bubble on in2)

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
  
  signal_out <= in1 and (not in2);

end architecture rtl;