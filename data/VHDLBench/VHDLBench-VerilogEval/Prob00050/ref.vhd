-- (3) Reference implementation (RefModule)
-- Reference Module: Karnaugh Map Circuit
-- Implements: out = a OR b OR c
-- Based on K-map analysis showing output is 1 except when abc=000
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = (a | b | c);
  signal_out <= a or b or c;

end architecture rtl;