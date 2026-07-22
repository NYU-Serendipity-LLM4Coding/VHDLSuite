-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity JC_counter is
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    Q     : out std_logic_vector(63 downto 0)
  );
end entity JC_counter;

architecture rtl of JC_counter is
  signal Q_reg : std_logic_vector(63 downto 0);
begin

  counter_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      Q_reg <= (others => '0');
    elsif rising_edge(clk) then
      if Q_reg(0) = '0' then
        Q_reg <= '1' & Q_reg(63 downto 1);
      else
        Q_reg <= '0' & Q_reg(63 downto 1);
      end if;
    end if;
  end process;
  
  Q <= Q_reg;
  
end architecture rtl;