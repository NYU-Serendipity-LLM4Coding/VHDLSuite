-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 7420 Dual 4-input NAND Gate

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    p1a : in  std_logic;
    p1b : in  std_logic;
    p1c : in  std_logic;
    p1d : in  std_logic;
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
  
  -- First 4-input NAND gate
  p1y <= not (p1a and p1b and p1c and p1d);
  
  -- Second 4-input NAND gate
  p2y <= not (p2a and p2b and p2c and p2d);

end architecture rtl;