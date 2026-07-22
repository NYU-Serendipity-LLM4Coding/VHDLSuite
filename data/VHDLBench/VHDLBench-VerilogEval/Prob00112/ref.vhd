-- (3) Reference implementation (RefModule)
-- Reference Module: 4-bit Priority Encoder
-- Returns position of first '1' bit (LSB has priority)
-- Returns 0 if no bits are set
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in : in  std_logic_vector(3 downto 0);
    pos       : out std_logic_vector(1 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) begin case (in) ... endcase end
  process(signal_in)
  begin
    case signal_in is
      when "0000" => pos <= "00";  -- 4'h0
      when "0001" => pos <= "00";  -- 4'h1
      when "0010" => pos <= "01";  -- 4'h2
      when "0011" => pos <= "00";  -- 4'h3
      when "0100" => pos <= "10";  -- 4'h4
      when "0101" => pos <= "00";  -- 4'h5
      when "0110" => pos <= "01";  -- 4'h6
      when "0111" => pos <= "00";  -- 4'h7
      when "1000" => pos <= "11";  -- 4'h8
      when "1001" => pos <= "00";  -- 4'h9
      when "1010" => pos <= "01";  -- 4'ha
      when "1011" => pos <= "00";  -- 4'hb
      when "1100" => pos <= "10";  -- 4'hc
      when "1101" => pos <= "00";  -- 4'hd
      when "1110" => pos <= "01";  -- 4'he
      when "1111" => pos <= "00";  -- 4'hf
      when others => pos <= "00";  -- default
    end case;
  end process;

end architecture rtl;