-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit even parity generator

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in : in  std_logic_vector(7 downto 0);
    parity    : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- XOR reduction for even parity
  parity <= signal_in(7) xor signal_in(6) xor signal_in(5) xor signal_in(4) xor
            signal_in(3) xor signal_in(2) xor signal_in(1) xor signal_in(0);

end architecture rtl;