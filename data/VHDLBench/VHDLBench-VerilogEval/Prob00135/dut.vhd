-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement FSM next-state logic for Y2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    y  : in  std_logic_vector(3 downto 1);
    w  : in  std_logic;
    Y2 : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal case_input : std_logic_vector(3 downto 0);
begin
  
  -- Concatenate y and w to form 4-bit case input
  case_input <= y & w;
  
  -- Implement next-state logic for Y2
  process(case_input)
  begin
    case case_input is
      when "0000" => Y2 <= '0';  -- 4'h0
      when "0001" => Y2 <= '0';  -- 4'h1
      when "0010" => Y2 <= '1';  -- 4'h2
      when "0011" => Y2 <= '1';  -- 4'h3
      when "0100" => Y2 <= '0';  -- 4'h4
      when "0101" => Y2 <= '1';  -- 4'h5
      when "0110" => Y2 <= '0';  -- 4'h6
      when "0111" => Y2 <= '0';  -- 4'h7
      when "1000" => Y2 <= '0';  -- 4'h8
      when "1001" => Y2 <= '1';  -- 4'h9
      when "1010" => Y2 <= '1';  -- 4'ha
      when "1011" => Y2 <= '1';  -- 4'hb
      when others => Y2 <= 'X';  -- default
    end case;
  end process;

end architecture rtl;