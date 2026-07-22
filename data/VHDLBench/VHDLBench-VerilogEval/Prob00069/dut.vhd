-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement the truth table using combinational logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    x3 : in  std_logic;
    x2 : in  std_logic;
    x1 : in  std_logic;
    f  : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implementation of truth table
  -- x3 x2 x1 | f
  -- 0  0  0  | 0
  -- 0  0  1  | 0
  -- 0  1  0  | 1
  -- 0  1  1  | 1
  -- 1  0  0  | 0
  -- 1  0  1  | 1
  -- 1  1  0  | 0
  -- 1  1  1  | 1
  
  f <= ((not x3) and x2 and (not x1)) or
       ((not x3) and x2 and x1) or
       (x3 and (not x2) and x1) or
       (x3 and x2 and x1);

end architecture rtl;