-- VHDL 2008 Implementation of 4-bit BCD Adder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_bcd is
  port (
    A   : in  std_logic_vector(3 downto 0);  -- First BCD number (0-9)
    B   : in  std_logic_vector(3 downto 0);  -- Second BCD number (0-9)
    Cin : in  std_logic;                     -- Input carry
    Sum : out std_logic_vector(3 downto 0);  -- BCD sum (0-9)
    Cout : out std_logic                     -- Output carry
  );
end entity adder_bcd;

architecture rtl of adder_bcd is
  signal temp_sum : unsigned(4 downto 0);        -- Temporary 5-bit sum
  signal corrected_sum : unsigned(4 downto 0);   -- Adjusted BCD sum
  signal carry_out : std_logic;                  -- Corrected carry-out
  
begin
  
  -- Step 1: Perform binary addition of A, B, and Cin
  temp_sum <= resize(unsigned(A), 5) + resize(unsigned(B), 5) + 
              ("0000" & Cin);
  
  -- Step 2: If sum is greater than 9, adjust by adding 6
  carry_out <= '1' when temp_sum > 9 else '0';
  corrected_sum <= temp_sum + 6 when temp_sum > 9 else temp_sum;
  
  -- Output the corrected sum and carry
  Sum <= std_logic_vector(corrected_sum(3 downto 0));
  Cout <= carry_out;
  
end architecture rtl;