-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Combinational circuit that produces q = a AND b
-- (Based on waveform analysis showing q=1 only when both a=1 and b=1)

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    q : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implement AND gate based on waveform analysis
  q <= a and b;

end architecture rtl;