-- (3) Reference implementation (RefModule)
-- Reference Module: Bit Reversal
-- Reverses the bit ordering of a 100-bit input vector
-- out[i] = in[99-i] for i = 0 to 99
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(99 downto 0);
    signal_out : out std_logic_vector(99 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always_comb for (int i=0; i<$bits(out); i++)
  --                     out[i] = in[$bits(out)-i-1];
  -- This reverses the bit order: out[0] = in[99], out[1] = in[98], etc.
  process(signal_in)
  begin
    for i in 0 to 99 loop
      signal_out(i) <= signal_in(99 - i);
    end loop;
  end process;

end architecture rtl;