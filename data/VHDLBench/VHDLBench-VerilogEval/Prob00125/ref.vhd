-- (3) Reference implementation (RefModule)
-- Reference Module: Karnaugh Map Implementation
-- Implements truth table with don't-care values
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    d          : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal abcd : std_logic_vector(3 downto 0);
begin
  
  -- Concatenate inputs {a,b,c,d}
  abcd <= a & b & c & d;
  
  -- Matches Verilog: always @(*) begin case({a,b,c,d}) ... endcase end
  process(a, b, c, d, abcd)
  begin
    case abcd is
      when "0000" => signal_out <= '0';  -- 4'h0
      when "0001" => signal_out <= '0';  -- 4'h1
      when "0010" => signal_out <= '1';  -- 4'h2
      when "0011" => signal_out <= '1';  -- 4'h3
      when "0100" => signal_out <= 'X';  -- 4'h4 (don't care)
      when "0101" => signal_out <= '0';  -- 4'h5
      when "0110" => signal_out <= '0';  -- 4'h6
      when "0111" => signal_out <= '0';  -- 4'h7
      when "1000" => signal_out <= '1';  -- 4'h8
      when "1001" => signal_out <= 'X';  -- 4'h9 (don't care)
      when "1010" => signal_out <= '1';  -- 4'ha
      when "1011" => signal_out <= '1';  -- 4'hb
      when "1100" => signal_out <= '1';  -- 4'hc
      when "1101" => signal_out <= 'X';  -- 4'hd (don't care)
      when "1110" => signal_out <= '1';  -- 4'he
      when "1111" => signal_out <= '1';  -- 4'hf
      when others => signal_out <= 'X';
    end case;
  end process;

end architecture rtl;