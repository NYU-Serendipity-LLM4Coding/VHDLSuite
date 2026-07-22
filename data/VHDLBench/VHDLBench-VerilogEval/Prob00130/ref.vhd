-- (3) Reference implementation (RefModule)
-- Reference Module: 4-to-1 Multiplexer with default
-- Select input based on control signal c:
--   c=0: q=b, c=1: q=e, c=2: q=a, c=3: q=d, else: q=4'hf

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a : in  std_logic_vector(3 downto 0);
    b : in  std_logic_vector(3 downto 0);
    c : in  std_logic_vector(3 downto 0);
    d : in  std_logic_vector(3 downto 0);
    e : in  std_logic_vector(3 downto 0);
    q : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) case (c) ... endcase
  process(a, b, c, d, e)
  begin
    case to_integer(unsigned(c)) is
      when 0      => q <= b;
      when 1      => q <= e;
      when 2      => q <= a;
      when 3      => q <= d;
      when others => q <= x"f";  -- Matches Verilog: default: q = 4'hf;
    end case;
  end process;

end architecture rtl;