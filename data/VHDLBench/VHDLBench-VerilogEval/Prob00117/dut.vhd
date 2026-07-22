-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement sequential counter with conditional load/reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk : in  std_logic;
    a   : in  std_logic;
    q   : out std_logic_vector(2 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : unsigned(2 downto 0) := (others => '0');
begin
  
  q <= std_logic_vector(q_reg);
  
  process(clk)
  begin
    if rising_edge(clk) then
      if a = '1' then
        q_reg <= to_unsigned(4, 3);
      elsif q_reg = 6 then
        q_reg <= to_unsigned(0, 3);
      else
        q_reg <= q_reg + 1;
      end if;
    end if;
  end process;

end architecture rtl;