-- (3) Reference implementation (RefModule)
-- Reference Module: SOP and POS Logic Minimization
-- Outputs logic-1 for inputs 2, 7, or 15
-- Outputs logic-0 for inputs 0, 1, 4, 5, 6, 9, 10, 13, 14
-- Don't-care for inputs 3, 8, 11, 12

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a       : in  std_logic;
    b       : in  std_logic;
    c       : in  std_logic;
    d       : in  std_logic;
    out_sop : out std_logic;
    out_pos : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal pos0, pos1 : std_logic;
begin
  
  -- Matches Verilog: assign out_sop = c&d | ~a&~b&c;
  -- Minimal SOP form
  out_sop <= (c and d) or ((not a) and (not b) and c);
  
  -- Matches Verilog: assign pos0 = c & (~b|d)&(~a|b);
  pos0 <= c and ((not b) or d) and ((not a) or b);
  
  -- Matches Verilog: assign pos1 = c & (~b|d)&(~a|d);
  pos1 <= c and ((not b) or d) and ((not a) or d);
  
  -- Matches Verilog: assign out_pos = (pos0 == pos1) ? pos0 : 1'bx;
  -- If pos0 and pos1 match, use that value; otherwise output don't-care
  out_pos <= pos0 when (pos0 = pos1) else '-';

end architecture rtl;