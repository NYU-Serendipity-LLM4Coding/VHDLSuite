-- (3) Reference implementation (RefModule)
-- Reference Module: Constant One Output
-- Output is always driven to logic '1'
-- Variable name changes: 'one' -> 'one_output' (better naming practice)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    one_output : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  -- Matches Verilog: assign one = 1'b1;
  one_output <= '1';
end architecture rtl;