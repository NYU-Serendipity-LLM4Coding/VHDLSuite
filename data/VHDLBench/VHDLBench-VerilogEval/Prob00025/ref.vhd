-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit Even Parity Generator
-- Computes XOR of all 8 input bits
-- Matches Verilog: assign parity = ^in;
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in : in  std_logic_vector(7 downto 0);
    parity    : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign parity = ^in;
  -- XOR reduction: parity is XOR of all bits in signal_in
  parity <= signal_in(7) xor signal_in(6) xor signal_in(5) xor signal_in(4) xor
            signal_in(3) xor signal_in(2) xor signal_in(1) xor signal_in(0);

end architecture rtl;