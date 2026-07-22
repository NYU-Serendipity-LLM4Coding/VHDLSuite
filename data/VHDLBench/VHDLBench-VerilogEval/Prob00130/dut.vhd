-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-to-1 multiplexer based on waveform analysis

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    a : in  std_logic_vector(3 downto 0);
    b : in  std_logic_vector(3 downto 0);
    c : in  std_logic_vector(3 downto 0);
    d : in  std_logic_vector(3 downto 0);
    e : in  std_logic_vector(3 downto 0);
    q : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(a, b, c, d, e)
  begin
    case to_integer(unsigned(c)) is
      when 0      => q <= b;
      when 1      => q <= e;
      when 2      => q <= a;
      when 3      => q <= d;
      when others => q <= x"f";
    end case;
  end process;

end architecture rtl;