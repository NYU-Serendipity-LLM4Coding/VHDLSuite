-- (3) Reference implementation (RefModule)
-- Reference Module: Karnaugh Map Function
-- Implements function with don't-care values
-- Uses case statement matching Verilog truth table
-- x[4:1] input, f output (with X for don't-care)

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
      when "0000" => f <= 'X';  -- 4'h0: f = 1'bx
      when "0001" => f <= 'X';  -- 4'h1: f = 1'bx
      when "0010" => f <= '0';  -- 4'h2: f = 0
      when "0011" => f <= 'X';  -- 4'h3: f = 1'bx
      when "0100" => f <= '1';  -- 4'h4: f = 1
      when "0101" => f <= 'X';  -- 4'h5: f = 1'bx
      when "0110" => f <= '1';  -- 4'h6: f = 1
      when "0111" => f <= '0';  -- 4'h7: f = 0
      when "1000" => f <= '0';  -- 4'h8: f = 0
      when "1001" => f <= '0';  -- 4'h9: f = 0
      when "1010" => f <= 'X';  -- 4'ha: f = 1'bx
      when "1011" => f <= '1';  -- 4'hb: f = 1
      when "1100" => f <= '1';  -- 4'hc: f = 1
      when "1101" => f <= 'X';  -- 4'hd: f = 1'bx
      when "1110" => f <= '1';  -- 4'he: f = 1
      when "1111" => f <= 'X';  -- 4'hf: f = 1'bx
      when others => f <= 'X';
    end case;
  end process;

end architecture rtl;