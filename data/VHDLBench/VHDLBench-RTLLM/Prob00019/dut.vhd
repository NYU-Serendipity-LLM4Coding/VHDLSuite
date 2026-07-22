-- (2) DUT implementation (sub_64bit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sub_64bit is
  port (
    A        : in  std_logic_vector(63 downto 0);
    B        : in  std_logic_vector(63 downto 0);
    result   : out std_logic_vector(63 downto 0);
    overflow : out std_logic
  );
end entity sub_64bit;

architecture rtl of sub_64bit is
  signal result_internal : signed(63 downto 0);
begin

  -- Perform subtraction
  result_internal <= signed(A) - signed(B);
  result <= std_logic_vector(result_internal);
  
  -- Overflow detection
  -- Overflow happens when the sign of A and B are different,
  -- but the sign of result matches B (i.e., differs from A)
  overflow <= '1' when (A(63) /= B(63)) and (result_internal(63) /= A(63)) else '0';

end architecture rtl;