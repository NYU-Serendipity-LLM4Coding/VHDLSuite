-- (3) Reference implementation (RefModule)
-- Reference Module: 6-to-1 Multiplexer
-- Selects one of 6 data inputs based on sel (0-5), outputs 0 otherwise
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
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
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) begin case (sel) ... endcase end
  process(sel, data0, data1, data2, data3, data4, data5)
  begin
    case sel is
      when "000" =>  -- 3'h0
        signal_out <= data0;
      when "001" =>  -- 3'h1
        signal_out <= data1;
      when "010" =>  -- 3'h2
        signal_out <= data2;
      when "011" =>  -- 3'h3
        signal_out <= data3;
      when "100" =>  -- 3'h4
        signal_out <= data4;
      when "101" =>  -- 3'h5
        signal_out <= data5;
      when others =>
        signal_out <= "0000";  -- 4'b0
    end case;
  end process;

end architecture rtl;