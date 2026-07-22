-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: XNOR gate

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- XNOR gate implementation
  signal_out <= not (a xor b);

end architecture rtl;