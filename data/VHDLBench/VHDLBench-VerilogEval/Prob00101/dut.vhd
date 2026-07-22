-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement the combinational circuit: q = c OR b
-- (Inputs a and d are not used in this particular circuit)

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
  
  -- Implement: q = c OR b
  q <= c or b;

end architecture rtl;