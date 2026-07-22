-- (3) Reference implementation (RefModule)
-- Reference Module: AND Gate
-- Two implementations: concurrent assignment and combinational process
-- Both compute: out = a AND b

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a               : in  std_logic;
    b               : in  std_logic;
    out_assign      : out std_logic;
    out_alwaysblock : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_assign = a & b;
  out_assign <= a and b;
  
  -- Matches Verilog: always @(*) out_alwaysblock = a & b;
  process(a, b)
  begin
    out_alwaysblock <= a and b;
  end process;

end architecture rtl;