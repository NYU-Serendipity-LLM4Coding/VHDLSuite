-- (3) Reference implementation (RefModule)
-- Reference Module: 100-bit 2-to-1 Multiplexer
-- Select b when sel=1, otherwise select a
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic_vector(99 downto 0);
    b          : in  std_logic_vector(99 downto 0);
    sel        : in  std_logic;
    signal_out : out std_logic_vector(99 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = sel ? b : a;
  signal_out <= b when sel = '1' else a;

end architecture rtl;