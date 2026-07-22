-- (3) Reference implementation (RefModule)
-- Reference Module: AND gate with inverted second input
-- Implements: out = in1 AND (NOT in2)
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    in1        : in  std_logic;
    in2        : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = in1 & ~in2;
  signal_out <= in1 and (not in2);

end architecture rtl;