-- 8-bit multiplier using shift-and-add algorithm
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_8bit is
  port (
    A       : in  std_logic_vector(7 downto 0);
    B       : in  std_logic_vector(7 downto 0);
    product : out std_logic_vector(15 downto 0)
  );
end entity multi_8bit;

architecture rtl of multi_8bit is
begin

  -- Combinational multiplication using shift-and-add
  process(A, B)
    variable temp_product : unsigned(15 downto 0);
    variable multiplicand : unsigned(15 downto 0);
    variable shift_count  : integer range 0 to 8;
  begin
    -- Initialize
    temp_product := (others => '0');
    multiplicand := resize(unsigned(A), 16);
    shift_count  := 0;
    
    -- Shift-and-add algorithm
    for i in 0 to 7 loop
      if B(i) = '1' then
        temp_product := temp_product + shift_left(multiplicand, shift_count);
      end if;
      shift_count := shift_count + 1;
    end loop;
    
    -- Output result
    product <= std_logic_vector(temp_product);
  end process;

end architecture rtl;