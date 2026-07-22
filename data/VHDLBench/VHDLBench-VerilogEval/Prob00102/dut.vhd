-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement the combinational circuit from waveform analysis
-- Circuit: q = (a OR b) AND (c OR d)

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    c : in  std_logic;
    d : in  std_logic;
    q : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implement: q = (a OR b) AND (c OR d)
  q <= (a or b) and (c or d);

end architecture rtl;