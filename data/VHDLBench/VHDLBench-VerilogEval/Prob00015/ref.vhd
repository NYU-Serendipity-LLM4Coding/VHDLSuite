-- (3) Reference implementation (RefModule)
-- Reference Module: 16-bit Word Splitter
-- Splits 16-bit input into high byte [15:8] and low byte [7:0]
-- Matches Verilog: assign {out_hi, out_lo} = in;
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in : in  std_logic_vector(15 downto 0);
    out_hi    : out std_logic_vector(7 downto 0);
    out_lo    : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign {out_hi, out_lo} = in;
  -- In VHDL, we use slicing instead of concatenation assignment
  out_hi <= signal_in(15 downto 8);  -- Upper byte
  out_lo <= signal_in(7 downto 0);   -- Lower byte

end architecture rtl;