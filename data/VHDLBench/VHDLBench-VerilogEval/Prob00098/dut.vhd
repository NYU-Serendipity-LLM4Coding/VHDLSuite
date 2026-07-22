-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: D flip-flop with inverted input

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    a   : in  std_logic;
    q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(clk)
  begin
    if rising_edge(clk) then
      q <= not a;
    end if;
  end process;

end architecture rtl;