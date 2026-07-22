-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Karnaugh map function
-- Can choose any value for don't-care positions

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    x : in  std_logic_vector(4 downto 1);
    f : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implementation using case statement
  -- Don't-care values filled with convenient choices
  process(x)
  begin
    case x is
      when "0000" => f <= '0';  -- Don't care - choose 0
      when "0001" => f <= '0';  -- Don't care - choose 0
      when "0010" => f <= '0';  -- Must be 0
      when "0011" => f <= '0';  -- Don't care - choose 0
      when "0100" => f <= '1';  -- Must be 1
      when "0101" => f <= '0';  -- Don't care - choose 0
      when "0110" => f <= '1';  -- Must be 1
      when "0111" => f <= '0';  -- Must be 0
      when "1000" => f <= '0';  -- Must be 0
      when "1001" => f <= '0';  -- Must be 0
      when "1010" => f <= '0';  -- Don't care - choose 0
      when "1011" => f <= '1';  -- Must be 1
      when "1100" => f <= '1';  -- Must be 1
      when "1101" => f <= '1';  -- Don't care - choose 1
      when "1110" => f <= '1';  -- Must be 1
      when "1111" => f <= '1';  -- Don't care - choose 1
      when others => f <= '0';
    end case;
  end process;

end architecture rtl;