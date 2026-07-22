-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: XNOR-XOR circuit
-- out = (in1 XNOR in2) XOR in3

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    in1        : in  std_logic;
    in2        : in  std_logic;
    in3        : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal xnor_result : std_logic;
begin
  
  -- Two-input XNOR (in1 XNOR in2)
  xnor_result <= not (in1 xor in2);
  
  -- Two-input XOR (XNOR_result XOR in3)
  signal_out <= xnor_result xor in3;

end architecture rtl;