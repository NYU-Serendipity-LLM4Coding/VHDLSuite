-- (3) Reference implementation (RefModule)
-- Reference Module: Constant Zero Output
-- Always outputs LOW (0)
-- Corresponds to Verilog: assign zero = 1'b0;

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    zero : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign zero = 1'b0;
  zero <= '0';

end architecture rtl;