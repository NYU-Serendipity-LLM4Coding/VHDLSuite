-- (3) Reference implementation (RefModule)
-- Reference Module: 256-to-1 Multiplexer (4-bit wide)
-- Selects 4 consecutive bits from 1024-bit input based on 8-bit selector
-- sel=0 selects in[3:0], sel=1 selects in[7:4], etc.
-- Matches Verilog: out = {in[sel*4+3], in[sel*4+2], in[sel*4+1], in[sel*4+0]}
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out' (VHDL keywords)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(1023 downto 0);
    sel        : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal base_index : integer range 0 to 1023;
begin
  
  -- Calculate base index: sel * 4
  -- In VHDL, we convert sel to integer, multiply by 4
  base_index <= to_integer(unsigned(sel)) * 4;
  
  -- Extract 4 bits starting from base_index
  -- Matches Verilog: {in[sel*4+3], in[sel*4+2], in[sel*4+1], in[sel*4+0]}
  -- Note: VHDL uses downto indexing, so we extract [base+3 downto base]
  signal_out <= signal_in(base_index + 3 downto base_index);

end architecture rtl;