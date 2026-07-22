-- (3) Reference implementation (RefModule)
-- Reference Module: Constant Zero Output
-- Circuit with no inputs, output always drives '0'
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = 1'b0;
  signal_out <= '0';

end architecture rtl;