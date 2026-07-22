-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Karnaugh map: out = a OR b OR c

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implement Karnaugh map logic
  -- K-map shows output is 1 for all cases except abc=000
  -- Simplified form: out = a OR b OR c
  signal_out <= a or b or c;

end architecture rtl;