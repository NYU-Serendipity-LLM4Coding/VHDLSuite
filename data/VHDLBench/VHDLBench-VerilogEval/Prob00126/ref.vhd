-- (3) Reference implementation (RefModule)
-- Reference Module: Combinational Lookup Table
-- 8-entry lookup table indexed by 3-bit input 'a'
-- Returns 16-bit output 'q' based on case statement
-- Matches Verilog decimal values: 0:4658, 1:44768, 2:10196, 3:23054, 4:8294, 5:25806, 6:50470, 7:12057

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a : in  std_logic_vector(2 downto 0);
    q : out std_logic_vector(15 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) case (a) ... endcase
  -- Combinational process with complete sensitivity list
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
      when others => q <= (others => '0');  -- Default case (shouldn't occur with 3-bit input)
    end case;
  end process;

end architecture rtl;