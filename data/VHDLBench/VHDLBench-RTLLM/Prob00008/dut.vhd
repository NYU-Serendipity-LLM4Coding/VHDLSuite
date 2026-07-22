-- VHDL 2008 Implementation of 4-bit Comparator
-- Translated from Verilog reference implementation
--
-- Key Translation Notes:
-- Verilog: {cout, diff} = A - B
--   In Verilog, this creates a 5-bit result where:
--   - cout = 1 means NO BORROW (A >= B)
--   - cout = 0 means BORROW occurred (A < B)
--   - diff = lower 4 bits of result
--
-- VHDL Translation Strategy:
--   Use direct comparison instead of subtraction-based borrow detection
--   to match the Verilog reference logic exactly.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator_4bit is
  port (
    A         : in  std_logic_vector(3 downto 0);
    B         : in  std_logic_vector(3 downto 0);
    A_greater : out std_logic;
    A_equal   : out std_logic;
    A_less    : out std_logic
  );
end entity comparator_4bit;

architecture rtl of comparator_4bit is
  signal A_unsigned : unsigned(3 downto 0);
  signal B_unsigned : unsigned(3 downto 0);
  signal diff : unsigned(3 downto 0);
  signal cout : std_logic;
begin

  -- Convert to unsigned for arithmetic
  A_unsigned <= unsigned(A);
  B_unsigned <= unsigned(B);
  
  -- Compute difference (lower 4 bits)
  diff <= A_unsigned - B_unsigned;
  
  -- Compute carry out (no borrow indicator)
  -- cout = 1 when A >= B, cout = 0 when A < B
  cout <= '1' when A_unsigned >= B_unsigned else '0';
  
  -- A > B: no borrow (cout = 1) AND difference is non-zero
  A_greater <= '1' when (cout = '1' and diff /= "0000") else '0';
  
  -- A == B: direct comparison
  A_equal <= '1' when (A = B) else '0';
  
  -- A < B: borrow occurred (cout = 0)
  A_less <= '1' when (cout = '0') else '0';

end architecture rtl;