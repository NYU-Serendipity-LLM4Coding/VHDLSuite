-- (3) Reference implementation (RefModule)
-- Reference Module: Bitwise OR, Logical OR, and NOT operations
-- Implements three operations on 3-bit vectors a and b
-- out_or_bitwise: bitwise OR of a and b
-- out_or_logical: logical OR (reduction OR of a) OR (reduction OR of b)
-- out_not: concatenation of ~b and ~a (bits [5:3] = ~b, bits [2:0] = ~a)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a              : in  std_logic_vector(2 downto 0);
    b              : in  std_logic_vector(2 downto 0);
    out_or_bitwise : out std_logic_vector(2 downto 0);
    out_or_logical : out std_logic;
    out_not        : out std_logic_vector(5 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Helper function for logical OR (reduction OR)
  function or_reduce(vec : std_logic_vector) return std_logic is
    variable result : std_logic := '0';
  begin
    for i in vec'range loop
      result := result or vec(i);
    end loop;
    return result;
  end function;
begin
  
  -- Matches Verilog: assign out_or_bitwise = a | b;
  out_or_bitwise <= a or b;
  
  -- Matches Verilog: assign out_or_logical = a || b;
  -- In Verilog, || is logical OR (true if either operand is non-zero)
  out_or_logical <= or_reduce(a) or or_reduce(b);
  
  -- Matches Verilog: assign out_not = {~b, ~a};
  -- Concatenation: bits [5:3] = ~b, bits [2:0] = ~a
  out_not <= (not b) & (not a);

end architecture rtl;