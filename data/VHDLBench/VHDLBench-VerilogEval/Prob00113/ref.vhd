-- (3) Reference implementation (RefModule)
-- Reference Module: Karnaugh Map Function Implementation
-- Implements truth table using case statement
-- Input x[4:1] maps to VHDL x(4 downto 1)
-- Karnaugh map defines output f for all 16 input combinations

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    x : in  std_logic_vector(4 downto 1);
    f : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always_comb begin case (x) ... endcase end
  process(x)
  begin
    case x is
      when "0000" => f <= '1';  -- 4'h0
      when "0001" => f <= '1';  -- 4'h1
      when "0010" => f <= '0';  -- 4'h2
      when "0011" => f <= '0';  -- 4'h3
      when "0100" => f <= '1';  -- 4'h4
      when "0101" => f <= '1';  -- 4'h5
      when "0110" => f <= '1';  -- 4'h6
      when "0111" => f <= '0';  -- 4'h7
      when "1000" => f <= '0';  -- 4'h8
      when "1001" => f <= '0';  -- 4'h9
      when "1010" => f <= '0';  -- 4'ha
      when "1011" => f <= '0';  -- 4'hb
      when "1100" => f <= '1';  -- 4'hc
      when "1101" => f <= '0';  -- 4'hd
      when "1110" => f <= '1';  -- 4'he
      when "1111" => f <= '1';  -- 4'hf
      when others => f <= '0';  -- Should never happen with 4-bit input
    end case;
  end process;

end architecture rtl;