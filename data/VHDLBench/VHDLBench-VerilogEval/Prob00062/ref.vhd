-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit 2-to-1 Multiplexer
-- When sel=1, output a; when sel=0, output b
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    sel        : in  std_logic;
    a          : in  std_logic_vector(7 downto 0);
    b          : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = sel ? a : b;
  signal_out <= a when sel = '1' else b;

end architecture rtl;