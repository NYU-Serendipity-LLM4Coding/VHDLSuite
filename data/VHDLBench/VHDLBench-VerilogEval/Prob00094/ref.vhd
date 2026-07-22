-- (3) Reference implementation (RefModule)
-- Reference Module: Bit Relationship Logic
-- Three outputs analyzing bit relationships:
--   out_both: AND of adjacent bits (left neighbor)
--   out_any: OR of adjacent bits (right neighbor)
--   out_different: XOR of adjacent bits (wrapping around)
-- Variable name changes: 'in' -> 'signal_in'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in     : in  std_logic_vector(3 downto 0);
    out_both      : out std_logic_vector(2 downto 0);
    out_any       : out std_logic_vector(3 downto 1);
    out_different : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_both = in[2:0] & in[3:1];
  -- out_both[i] = in[i] AND in[i+1]
  out_both <= signal_in(2 downto 0) and signal_in(3 downto 1);
  
  -- Matches Verilog: assign out_any = in[2:0] | in[3:1];
  -- out_any[i] = in[i] OR in[i-1]
  out_any <= signal_in(2 downto 0) or signal_in(3 downto 1);
  
  -- Matches Verilog: assign out_different = in ^ {in[0], in[3:1]};
  -- out_different[i] = in[i] XOR in[(i+1) mod 4] (wrapping)
  -- {in[0], in[3:1]} creates the rotated vector
  out_different <= signal_in xor (signal_in(0) & signal_in(3 downto 1));

end architecture rtl;