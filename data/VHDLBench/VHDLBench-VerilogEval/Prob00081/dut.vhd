-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement 7458 chip functionality

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    p1a : in  std_logic;
    p1b : in  std_logic;
    p1c : in  std_logic;
    p1d : in  std_logic;
    p1e : in  std_logic;
    p1f : in  std_logic;
    p1y : out std_logic;
    p2a : in  std_logic;
    p2b : in  std_logic;
    p2c : in  std_logic;
    p2d : in  std_logic;
    p2y : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Method 1: Direct concurrent assignment
  p1y <= (p1a and p1b and p1c) or (p1d and p1e and p1f);
  p2y <= (p2a and p2b) or (p2c and p2d);
  
  -- Alternative method with intermediate signals:
  -- signal and1, and2, and3, and4 : std_logic;
  -- and1 <= p1a and p1b and p1c;
  -- and2 <= p1d and p1e and p1f;
  -- and3 <= p2a and p2b;
  -- and4 <= p2c and p2d;
  -- p1y <= and1 or and2;
  -- p2y <= and3 or and4;

end architecture rtl;