-- (3) Reference implementation (RefModule)
-- Reference Module: Bit Reversal
-- Reverses the bit ordering of an 8-bit input vector
-- in[7:0] -> out[0:7] (i.e., in(7) -> out(0), in(6) -> out(1), etc.)
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign {out[0],out[1],out[2],out[3],out[4],out[5],out[6],out[7]} = in;
  -- This reverses the bit order
  signal_out(0) <= signal_in(7);
  signal_out(1) <= signal_in(6);
  signal_out(2) <= signal_in(5);
  signal_out(3) <= signal_in(4);
  signal_out(4) <= signal_in(3);
  signal_out(5) <= signal_in(2);
  signal_out(6) <= signal_in(1);
  signal_out(7) <= signal_in(0);

end architecture rtl;