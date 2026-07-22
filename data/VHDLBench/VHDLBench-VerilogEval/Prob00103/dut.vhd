-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: q = NOT(a XOR b XOR c XOR d)

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
  q <= not (a xor b xor c xor d);
end architecture rtl;