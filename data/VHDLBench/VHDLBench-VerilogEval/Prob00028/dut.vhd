-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: D Latch using process block

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    d   : in  std_logic;
    ena : in  std_logic;
    q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- D Latch implementation
  -- Transparent when ena='1': q follows d
  -- Holds value when ena='0'
  process(d, ena)
  begin
    if ena = '1' then
      q <= d;
    end if;
  end process;

end architecture rtl;