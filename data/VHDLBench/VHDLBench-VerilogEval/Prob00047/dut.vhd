-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit D flip-flops with async active-high reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk    : in  std_logic;
    d      : in  std_logic_vector(7 downto 0);
    areset : in  std_logic;
    q      : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(clk, areset)
  begin
    if areset = '1' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;