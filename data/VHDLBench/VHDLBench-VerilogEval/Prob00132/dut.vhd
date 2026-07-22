-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must fix bugs: Add else clauses to prevent latches

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    cpu_overheated    : in  std_logic;
    arrived           : in  std_logic;
    gas_tank_empty    : in  std_logic;
    shut_off_computer : out std_logic;
    keep_driving      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- First process: shut_off_computer logic
  -- Bug fix: Added else clause (was missing in original buggy code)
  process(cpu_overheated)
  begin
    if cpu_overheated = '1' then
      shut_off_computer <= '1';
    else
      shut_off_computer <= '0';  -- BUG FIX: Added this else clause
    end if;
  end process;
  
  -- Second process: keep_driving logic
  -- Bug fix: Added else clause (was missing in original buggy code)
  process(arrived, gas_tank_empty)
  begin
    if arrived = '0' then
      keep_driving <= not gas_tank_empty;
    else
      keep_driving <= '0';  -- BUG FIX: Added this else clause
    end if;
  end process;

end architecture rtl;