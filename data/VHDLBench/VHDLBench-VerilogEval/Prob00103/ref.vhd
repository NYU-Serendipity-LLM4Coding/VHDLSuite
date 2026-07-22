-- (3) Reference implementation (RefModule)
-- Reference Module: Combinational XOR circuit
-- Implements q = NOT(a XOR b XOR c XOR d)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a : in  std_logic;
    b : in  std_logic;
    c : in  std_logic;
    d : in  std_logic;
    q : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  -- Matches Verilog: assign q = ~a^b^c^d;
  -- In Verilog, this is: NOT(a XOR b XOR c XOR d)
  q <= not (a xor b xor c xor d);
end architecture rtl;