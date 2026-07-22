-- (3) Reference implementation (RefModule)
-- Reference Module: 256-to-1 Multiplexer
-- Selects one bit from 256-bit input vector based on 8-bit selector
-- Matches Verilog: assign out = in[sel];
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out' (VHDL keywords)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(255 downto 0);
    sel        : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = in[sel];
  -- Convert sel to integer index for array access
  signal_out <= signal_in(to_integer(unsigned(sel)));

end architecture rtl;