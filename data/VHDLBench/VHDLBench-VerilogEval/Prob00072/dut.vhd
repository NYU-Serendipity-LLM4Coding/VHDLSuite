-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement thermostat controller logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    mode     : in  std_logic;
    too_cold : in  std_logic;
    too_hot  : in  std_logic;
    fan_on   : in  std_logic;
    heater   : out std_logic;
    aircon   : out std_logic;
    fan      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal fan_condition : std_logic;
begin
  
  -- Fan turns on when:
  -- - In heating mode (mode=1) and too_cold=1, OR
  -- - In cooling mode (mode=0) and too_hot=1, OR
  -- - User requests fan (fan_on=1)
  fan_condition <= too_cold when mode = '1' else too_hot;
  fan <= fan_condition or fan_on;
  
  -- Heater: only in heating mode when too cold
  heater <= mode and too_cold;
  
  -- Air conditioner: only in cooling mode when too hot
  aircon <= (not mode) and too_hot;

end architecture rtl;