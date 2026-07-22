-- (3) Reference implementation (RefModule)
-- Reference Module: Heating/Cooling Thermostat Controller
-- Controls heater, air conditioner, and fan based on mode and temperature
-- Matches Verilog reference implementation

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    mode     : in  std_logic;
    too_cold : in  std_logic;
    too_hot  : in  std_logic;
    fan_on   : in  std_logic;
    heater   : out std_logic;
    aircon   : out std_logic;
    fan      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal fan_condition : std_logic;
begin
  
  -- Matches Verilog: assign fan = (mode ? too_cold : too_hot) | fan_on;
  -- fan_condition = mode ? too_cold : too_hot (mux)
  fan_condition <= too_cold when mode = '1' else too_hot;
  fan <= fan_condition or fan_on;
  
  -- Matches Verilog: assign heater = (mode & too_cold);
  heater <= mode and too_cold;
  
  -- Matches Verilog: assign aircon = (~mode & too_hot);
  aircon <= (not mode) and too_hot;

end architecture rtl;