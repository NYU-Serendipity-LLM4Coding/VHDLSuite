-- (3) Reference implementation (RefModule)
-- Reference Module: Cellphone Ringer/Motor Control
-- ringer = ring AND NOT vibrate_mode
-- motor  = ring AND vibrate_mode

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    ring         : in  std_logic;
    vibrate_mode : in  std_logic;
    ringer       : out std_logic;
    motor        : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign ringer = ring & ~vibrate_mode;
  ringer <= ring and (not vibrate_mode);
  
  -- Matches Verilog: assign motor = ring & vibrate_mode;
  motor <= ring and vibrate_mode;

end architecture rtl;