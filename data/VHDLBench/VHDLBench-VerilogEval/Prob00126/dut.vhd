-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement the same lookup table as RefModule

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    a : in  std_logic_vector(2 downto 0);
    q : out std_logic_vector(15 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Combinational lookup table
  process(a)
  begin
    case a is
      when "000" => q <= std_logic_vector(to_unsigned(4658, 16));   -- 0x1232
      when "001" => q <= std_logic_vector(to_unsigned(44768, 16));  -- 0xAEE0
      when "010" => q <= std_logic_vector(to_unsigned(10196, 16));  -- 0x27D4
      when "011" => q <= std_logic_vector(to_unsigned(23054, 16));  -- 0x5A0E
      when "100" => q <= std_logic_vector(to_unsigned(8294, 16));   -- 0x2066
      when "101" => q <= std_logic_vector(to_unsigned(25806, 16));  -- 0x64CE
      when "110" => q <= std_logic_vector(to_unsigned(50470, 16));  -- 0xC526
      when "111" => q <= std_logic_vector(to_unsigned(12057, 16));  -- 0x2F19
      when others => q <= (others => '0');
    end case;
  end process;

end architecture rtl;