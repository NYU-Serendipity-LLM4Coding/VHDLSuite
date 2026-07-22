-- (3) Reference implementation (RefModule)
-- Reference Module: 4-Input Gates (AND, OR, XOR)
-- Implements reduction operations on 4-bit input
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in : in  std_logic_vector(3 downto 0);
    out_and   : out std_logic;
    out_or    : out std_logic;
    out_xor   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_and = &in;
  -- Reduction AND: all bits must be '1'
  out_and <= signal_in(3) and signal_in(2) and signal_in(1) and signal_in(0);
  
  -- Matches Verilog: assign out_or = |in;
  -- Reduction OR: at least one bit must be '1'
  out_or <= signal_in(3) or signal_in(2) or signal_in(1) or signal_in(0);
  
  -- Matches Verilog: assign out_xor = ^in;
  -- Reduction XOR: odd parity check
  out_xor <= signal_in(3) xor signal_in(2) xor signal_in(1) xor signal_in(0);

end architecture rtl;