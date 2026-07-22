-- (2) DUT implementation (up_down_counter)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_down_counter is
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    up_down : in  std_logic;
    count   : out std_logic_vector(15 downto 0)
  );
end entity up_down_counter;

architecture rtl of up_down_counter is
  signal count_reg : unsigned(15 downto 0);
begin

  counter_proc : process(clk, reset)
  begin
    if reset = '1' then
      count_reg <= (others => '0');
    elsif rising_edge(clk) then
      if up_down = '1' then
        if count_reg = to_unsigned(65535, 16) then
          count_reg <= (others => '0');
        else
          count_reg <= count_reg + 1;
        end if;
      else
        if count_reg = to_unsigned(0, 16) then
          count_reg <= to_unsigned(65535, 16);
        else
          count_reg <= count_reg - 1;
        end if;
      end if;
    end if;
  end process;
  
  count <= std_logic_vector(count_reg);

end architecture rtl;