-- (3) Reference implementation (RefModule)
-- Reference Module: 2-to-1 Multiplexer
-- When sel=0, choose a. When sel=1, choose b.
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    sel        : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = sel ? b : a;
  signal_out <= b when sel = '1' else a;

end architecture rtl;