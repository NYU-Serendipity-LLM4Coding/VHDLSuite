-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: out = (a AND b) OR (c AND d), out_n = NOT out

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a            : in  std_logic;
    b            : in  std_logic;
    c            : in  std_logic;
    d            : in  std_logic;
    signal_out   : out std_logic;
    signal_out_n : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  -- Intermediate wires to connect AND and OR gates
  signal w1 : std_logic;
  signal w2 : std_logic;
begin
  
  -- First layer: AND gates
  w1 <= a and b;
  w2 <= c and d;
  
  -- Second layer: OR gate
  signal_out <= w1 or w2;
  
  -- Inverted output
  signal_out_n <= not signal_out;

end architecture rtl;