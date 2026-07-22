-- (3) Reference implementation (RefModule)
-- Reference Module: NOR gate
-- Implements: out = NOT(a OR b)
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = ~(a | b);
  signal_out <= not (a or b);

end architecture rtl;