-- (3) Reference implementation (RefModule)
-- Reference Module: 100-bit Neighbor Comparison
-- Three operations:
--   1. out_both[i]: in[i] AND in[i+1] (both neighbors to left)
--   2. out_any[i]: in[i] OR in[i-1] (any neighbor to right)
--   3. out_different[i]: in[i] XOR in[wrap_left] (difference with wrapping)
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in     : in  std_logic_vector(99 downto 0);
    out_both      : out std_logic_vector(98 downto 0);
    out_any       : out std_logic_vector(99 downto 1);
    out_different : out std_logic_vector(99 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_both = in & in[99:1];
  -- out_both[i] = in[i] AND in[i+1] for i=0 to 98
  -- Verilog in[99:1] shifts right: {in[99], in[98], ..., in[1]}
  out_both <= signal_in(98 downto 0) and signal_in(99 downto 1);
  
  -- Matches Verilog: assign out_any = in | in[99:1];
  -- out_any[i] = in[i] OR in[i-1] for i=1 to 99
  -- Verilog in[99:1] is {in[99], in[98], ..., in[1]}
  -- VHDL: signal_in(99 downto 1) is correct mapping
  out_any <= signal_in(99 downto 1) or signal_in(98 downto 0);
  
  -- Matches Verilog: assign out_different = in ^ {in[0], in[99:1]};
  -- Wrapping: compare each bit with left neighbor (circular)
  -- Verilog {in[0], in[99:1]} creates {in[0], in[99], in[98], ..., in[1]}
  -- This shifts right and wraps in[0] to MSB position
  out_different <= signal_in xor (signal_in(0) & signal_in(99 downto 1));

end architecture rtl;