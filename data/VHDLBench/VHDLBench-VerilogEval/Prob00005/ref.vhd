-- (3) Reference implementation (RefModule)
-- Reference Module: NOT gate
-- Simple inverter implementation
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out' (VHDL keywords)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  -- Matches Verilog: assign out = ~in;
  signal_out <= not signal_in;
end architecture rtl;