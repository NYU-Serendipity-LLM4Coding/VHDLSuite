-- (3) Reference implementation (RefModule)
-- Reference Module: Combinational Logic Circuit
-- Implements: q = (a OR b) AND (c OR d)
-- Truth table verification from waveform analysis

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
  
  -- Matches Verilog: assign q = (a|b) & (c|d);
  q <= (a or b) and (c or d);

end architecture rtl;