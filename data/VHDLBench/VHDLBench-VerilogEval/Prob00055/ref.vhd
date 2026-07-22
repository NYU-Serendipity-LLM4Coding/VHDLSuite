-- (3) Reference implementation (RefModule)
-- Reference Module: Minimum Finder
-- Finds minimum of four 8-bit unsigned numbers
-- Matches Verilog: always_comb with sequential comparisons

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    a   : in  std_logic_vector(7 downto 0);
    b   : in  std_logic_vector(7 downto 0);
    c   : in  std_logic_vector(7 downto 0);
    d   : in  std_logic_vector(7 downto 0);
    min : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always_comb begin ... end
  process(a, b, c, d)
    variable min_temp : unsigned(7 downto 0);
  begin
    -- min = a;
    min_temp := unsigned(a);
    
    -- if (min > b) min = b;
    if min_temp > unsigned(b) then
      min_temp := unsigned(b);
    end if;
    
    -- if (min > c) min = c;
    if min_temp > unsigned(c) then
      min_temp := unsigned(c);
    end if;
    
    -- if (min > d) min = d;
    if min_temp > unsigned(d) then
      min_temp := unsigned(d);
    end if;
    
    min <= std_logic_vector(min_temp);
  end process;

end architecture rtl;