-- (3) Reference implementation (RefModule)
-- Reference Module: Combinational Circuit (c OR b)
-- From the waveform analysis: q = c | b
-- This is a simple 2-input OR gate using inputs b and c

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    c : in  std_logic;
    d : in  std_logic;
    q : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign q = c | b;
  q <= c or b;

end architecture rtl;