-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement cellphone ringer/motor control logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    ring         : in  std_logic;
    vibrate_mode : in  std_logic;
    ringer       : out std_logic;
    motor        : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Turn on ringer when ringing but NOT in vibrate mode
  ringer <= ring and (not vibrate_mode);
  
  -- Turn on motor when ringing AND in vibrate mode
  motor <= ring and vibrate_mode;

end architecture rtl;