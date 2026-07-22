-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 6-to-1 multiplexer with 4-bit data

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    sel        : in  std_logic_vector(2 downto 0);
    data0      : in  std_logic_vector(3 downto 0);
    data1      : in  std_logic_vector(3 downto 0);
    data2      : in  std_logic_vector(3 downto 0);
    data3      : in  std_logic_vector(3 downto 0);
    data4      : in  std_logic_vector(3 downto 0);
    data5      : in  std_logic_vector(3 downto 0);
    signal_out : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(sel, data0, data1, data2, data3, data4, data5)
  begin
    case sel is
      when "000" =>
        signal_out <= data0;
      when "001" =>
        signal_out <= data1;
      when "010" =>
        signal_out <= data2;
      when "011" =>
        signal_out <= data3;
      when "100" =>
        signal_out <= data4;
      when "101" =>
        signal_out <= data5;
      when others =>
        signal_out <= "0000";
    end case;
  end process;

end architecture rtl;