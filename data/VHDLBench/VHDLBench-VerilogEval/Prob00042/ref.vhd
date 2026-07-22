-- (3) Reference implementation (RefModule)
-- Reference Module: Sign Extension Circuit
-- Extends an 8-bit signed number to 32 bits
-- Replicates the sign bit (in(7)) 24 times and concatenates with input
-- Matches Verilog: assign out = { {24{in[7]}}, in };
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(31 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Sign extension: replicate bit 7 (sign bit) 24 times, then concatenate with input
  -- Matches Verilog: assign out = { {24{in[7]}}, in };
  signal_out <= (31 downto 8 => signal_in(7)) & signal_in;

end architecture rtl;