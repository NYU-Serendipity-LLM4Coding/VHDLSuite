-- (3) Reference implementation (RefModule)
-- Reference Module: FSM Next-State Logic for Y2 (bit 2 of next state)
-- Implements case statement based on concatenation {y[3:1], w}
-- Truth table for Y2 output based on current state and input

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    y  : in  std_logic_vector(3 downto 1);
    w  : in  std_logic;
    Y2 : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal case_input : std_logic_vector(3 downto 0);
begin
  
  -- Concatenate y and w to form 4-bit case input
  -- Matches Verilog: case ({y, w})
  case_input <= y & w;
  
  -- Matches Verilog: always_comb begin case ({y, w}) ... endcase end
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
      when others => Y2 <= 'X';  -- default: Y2 = 1'bx
    end case;
  end process;

end architecture rtl;