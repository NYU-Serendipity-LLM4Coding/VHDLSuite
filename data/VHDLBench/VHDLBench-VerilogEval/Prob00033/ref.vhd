-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit Signed Adder with Overflow Detection
-- Adds two 8-bit signed numbers and detects overflow
-- Overflow occurs when: same sign inputs produce opposite sign output

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a        : in  std_logic_vector(7 downto 0);
    b        : in  std_logic_vector(7 downto 0);
    s        : out std_logic_vector(7 downto 0);
    overflow : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: wire [8:0] sum = a+b;
  signal sum : std_logic_vector(8 downto 0);
begin
  
  -- 9-bit addition (extends to catch carry)
  -- Matches Verilog: wire [8:0] sum = a+b;
  sum <= std_logic_vector(resize(unsigned(a), 9) + resize(unsigned(b), 9));
  
  -- Extract lower 8 bits as result
  -- Matches Verilog: assign s = sum[7:0];
  s <= sum(7 downto 0);
  
  -- Overflow detection for signed addition:
  -- Overflow occurs when operands have same sign but result has different sign
  -- Matches Verilog: assign overflow = !(a[7]^b[7]) && (a[7] != s[7]);
  overflow <= (not (a(7) xor b(7))) and (a(7) xor sum(7));

end architecture rtl;