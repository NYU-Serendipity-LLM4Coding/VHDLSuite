-- (3) Reference implementation (RefModule)
-- Reference Module: AND-OR-NOT Circuit
-- Circuit: out = (a AND b) OR (c AND d), out_n = NOT out
-- Variable name changes: 'out' -> 'signal_out', 'out_n' -> 'signal_out_n' (VHDL keywords)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a            : in  std_logic;
    b            : in  std_logic;
    c            : in  std_logic;
    d            : in  std_logic;
    signal_out   : out std_logic;
    signal_out_n : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Intermediate wires (matches Verilog: wire w1, w2;)
  signal w1 : std_logic;
  signal w2 : std_logic;
begin
  
  -- Matches Verilog: assign w1 = a&b;
  w1 <= a and b;
  
  -- Matches Verilog: assign w2 = c&d;
  w2 <= c and d;
  
  -- Matches Verilog: assign out = w1|w2;
  signal_out <= w1 or w2;
  
  -- Matches Verilog: assign out_n = ~out;
  signal_out_n <= not signal_out;

end architecture rtl;