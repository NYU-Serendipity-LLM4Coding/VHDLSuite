-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 100-bit left/right rotator with synchronous load

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    ena  : in  std_logic_vector(1 downto 0);
    data : in  std_logic_vector(99 downto 0);
    q    : out std_logic_vector(99 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(99 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        q_reg <= data;
      elsif ena = "01" then
        -- Rotate right
        q_reg <= q_reg(0) & q_reg(99 downto 1);
      elsif ena = "10" then
        -- Rotate left
        q_reg <= q_reg(98 downto 0) & q_reg(99);
      end if;
    end if;
  end process;

end architecture rtl;