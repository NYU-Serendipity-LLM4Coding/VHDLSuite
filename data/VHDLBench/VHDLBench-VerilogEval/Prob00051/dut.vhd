-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-input AND, OR, and XOR gates

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in : in  std_logic_vector(3 downto 0);
    out_and   : out std_logic;
    out_or    : out std_logic;
    out_xor   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- 4-input AND gate (reduction AND)
  out_and <= signal_in(3) and signal_in(2) and signal_in(1) and signal_in(0);
  
  -- 4-input OR gate (reduction OR)
  out_or <= signal_in(3) or signal_in(2) or signal_in(1) or signal_in(0);
  
  -- 4-input XOR gate (reduction XOR)
  out_xor <= signal_in(3) xor signal_in(2) xor signal_in(1) xor signal_in(0);

end architecture rtl;