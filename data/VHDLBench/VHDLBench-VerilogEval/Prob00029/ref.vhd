-- (3) Reference implementation (RefModule)
-- Reference Module: XNOR-XOR Circuit
-- Implements: out = (in1 XNOR in2) XOR in3
-- Verilog: assign out = (~(in1 ^ in2)) ^ in3;
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    in1        : in  std_logic;
    in2        : in  std_logic;
    in3        : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal xnor_result : std_logic;
begin
  
  -- Matches Verilog: assign out = (~(in1 ^ in2)) ^ in3;
  -- XNOR: ~(in1 ^ in2) is equivalent to (in1 XNOR in2)
  xnor_result <= not (in1 xor in2);
  signal_out  <= xnor_result xor in3;

end architecture rtl;