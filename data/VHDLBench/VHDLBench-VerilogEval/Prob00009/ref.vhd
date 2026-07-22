-- (3) Reference implementation (RefModule)
-- Reference Module: Population Count Circuit
-- Counts number of '1's in 3-bit input vector
-- Matches Verilog: assign out = in[0]+in[1]+in[2];
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(2 downto 0);
    signal_out : out std_logic_vector(1 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal count : unsigned(1 downto 0);
begin
  
  -- Population count: sum the three bits
  -- Matches Verilog: assign out = in[0]+in[1]+in[2];
  -- FIXED: Use character '0' not string "0" in concatenation
  count <= resize(unsigned'('0' & signal_in(0)), 2) + 
           resize(unsigned'('0' & signal_in(1)), 2) + 
           resize(unsigned'('0' & signal_in(2)), 2);
  
  signal_out <= std_logic_vector(count);

end architecture rtl;