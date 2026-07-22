-- (3) Reference implementation (RefModule)
-- Reference Module: Karnaugh Map Circuit Implementation
-- Implements the boolean function from the K-map
-- out = (~c & ~b) | (~d & ~a) | (a & c & d) | (b & c & d)
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    d          : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out = (~c & ~b) | (~d&~a) | (a&c&d) | (b&c&d);
  signal_out <= ((not c) and (not b)) or 
                ((not d) and (not a)) or 
                (a and c and d) or 
                (b and c and d);

end architecture rtl;