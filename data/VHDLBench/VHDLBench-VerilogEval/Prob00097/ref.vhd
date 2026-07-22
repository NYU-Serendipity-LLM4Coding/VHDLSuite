-- (3) Reference implementation (RefModule)
-- Reference Module: 9-to-1 Multiplexer (16-bit wide)
-- Selects one of 9 inputs (a-i) based on sel (0-8)
-- For sel=9 to 15, output is all '1's
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a          : in  std_logic_vector(15 downto 0);
    b          : in  std_logic_vector(15 downto 0);
    c          : in  std_logic_vector(15 downto 0);
    d          : in  std_logic_vector(15 downto 0);
    e          : in  std_logic_vector(15 downto 0);
    f          : in  std_logic_vector(15 downto 0);
    g          : in  std_logic_vector(15 downto 0);
    h          : in  std_logic_vector(15 downto 0);
    i          : in  std_logic_vector(15 downto 0);
    sel        : in  std_logic_vector(3 downto 0);
    signal_out : out std_logic_vector(15 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin

  -- Matches Verilog: always @(*) begin ... case (sel) ... endcase end
  process(a, b, c, d, e, f, g, h, i, sel)
  begin
    -- Default: Matches Verilog: out = '1;
    signal_out <= (others => '1');
    
    case sel is
      when x"0" => signal_out <= a;
      when x"1" => signal_out <= b;
      when x"2" => signal_out <= c;
      when x"3" => signal_out <= d;
      when x"4" => signal_out <= e;
      when x"5" => signal_out <= f;
      when x"6" => signal_out <= g;
      when x"7" => signal_out <= h;
      when x"8" => signal_out <= i;
      when others => signal_out <= (others => '1');
    end case;
  end process;

end architecture rtl;