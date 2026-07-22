-- (3) Reference implementation (RefModule)
-- Reference Module: Byte Order Reversal
-- Reverses the byte order of a 32-bit vector
-- Input:  in[31:24] in[23:16] in[15:8] in[7:0]
-- Output: in[7:0]   in[15:8]  in[23:16] in[31:24]
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(31 downto 0);
    signal_out : out std_logic_vector(31 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = {in[7:0], in[15:8], in[23:16], in[31:24]};
  -- Verilog concatenation {a, b, c, d} maps to VHDL: d & c & b & a
  -- Note: VHDL indexing is reversed compared to Verilog
  signal_out <= signal_in(7 downto 0) & signal_in(15 downto 8) & 
                signal_in(23 downto 16) & signal_in(31 downto 24);

end architecture rtl;