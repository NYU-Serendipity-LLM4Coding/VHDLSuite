-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-bit right shift register with async reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk    : in  std_logic;
    areset : in  std_logic;
    load   : in  std_logic;
    ena    : in  std_logic;
    data   : in  std_logic_vector(3 downto 0);
    q      : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(3 downto 0) := "0000";
begin
  
  q <= q_reg;
  
  process(clk, areset)
  begin
    if areset = '1' then
      q_reg <= "0000";
    elsif rising_edge(clk) then
      if load = '1' then
        q_reg <= data;
      elsif ena = '1' then
        q_reg <= '0' & q_reg(3 downto 1);
      end if;
    end if;
  end process;

end architecture rtl;