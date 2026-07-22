-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must find minimum of four 8-bit unsigned numbers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    a   : in  std_logic_vector(7 downto 0);
    b   : in  std_logic_vector(7 downto 0);
    c   : in  std_logic_vector(7 downto 0);
    d   : in  std_logic_vector(7 downto 0);
    min : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(a, b, c, d)
    variable min_temp : unsigned(7 downto 0);
  begin
    min_temp := unsigned(a);
    
    if min_temp > unsigned(b) then
      min_temp := unsigned(b);
    end if;
    
    if min_temp > unsigned(c) then
      min_temp := unsigned(c);
    end if;
    
    if min_temp > unsigned(d) then
      min_temp := unsigned(d);
    end if;
    
    min <= std_logic_vector(min_temp);
  end process;

end architecture rtl;