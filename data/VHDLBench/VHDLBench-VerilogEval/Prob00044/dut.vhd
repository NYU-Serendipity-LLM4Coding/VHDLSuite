-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: bitwise OR, logical OR, and NOT operations

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a              : in  std_logic_vector(2 downto 0);
    b              : in  std_logic_vector(2 downto 0);
    out_or_bitwise : out std_logic_vector(2 downto 0);
    out_or_logical : out std_logic;
    out_not        : out std_logic_vector(5 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
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
  
  -- Bitwise OR
  out_or_bitwise <= a or b;
  
  -- Logical OR (true if either vector is non-zero)
  out_or_logical <= or_reduce(a) or or_reduce(b);
  
  -- Concatenate inverted vectors: {~b, ~a}
  out_not <= (not b) & (not a);

end architecture rtl;