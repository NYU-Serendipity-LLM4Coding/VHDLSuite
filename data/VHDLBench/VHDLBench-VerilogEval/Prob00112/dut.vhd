-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-bit priority encoder
-- Returns position of first '1' bit (LSB has priority)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in : in  std_logic_vector(3 downto 0);
    pos       : out std_logic_vector(1 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(signal_in)
  begin
    case signal_in is
      when "0000" => pos <= "00";
      when "0001" => pos <= "00";
      when "0010" => pos <= "01";
      when "0011" => pos <= "00";
      when "0100" => pos <= "10";
      when "0101" => pos <= "00";
      when "0110" => pos <= "01";
      when "0111" => pos <= "00";
      when "1000" => pos <= "11";
      when "1001" => pos <= "00";
      when "1010" => pos <= "01";
      when "1011" => pos <= "00";
      when "1100" => pos <= "10";
      when "1101" => pos <= "00";
      when "1110" => pos <= "01";
      when "1111" => pos <= "00";
      when others => pos <= "00";
    end case;
  end process;

end architecture rtl;