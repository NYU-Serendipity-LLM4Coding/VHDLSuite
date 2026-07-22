-- (2) DUT implementation (freq_divbyeven)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_divbyeven is
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    clk_div  : out std_logic
  );
end entity freq_divbyeven;

architecture rtl of freq_divbyeven is
  constant NUM_DIV : integer := 6;
  signal cnt : unsigned(3 downto 0) := (others => '0');
  signal clk_div_reg : std_logic := '0';
begin
  clk_div <= clk_div_reg;
  
  divider_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt <= (others => '0');
      clk_div_reg <= '0';
    elsif rising_edge(clk) then
      if cnt < to_unsigned(NUM_DIV / 2 - 1, 4) then
        cnt <= cnt + 1;
      else
        cnt <= (others => '0');
        clk_div_reg <= not clk_div_reg;
      end if;
    end if;
  end process;
end architecture rtl;