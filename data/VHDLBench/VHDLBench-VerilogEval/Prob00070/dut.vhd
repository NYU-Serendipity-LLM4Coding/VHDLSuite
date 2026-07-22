-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement minimal SOP and POS forms

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a       : in  std_logic;
    b       : in  std_logic;
    c       : in  std_logic;
    d       : in  std_logic;
    out_sop : out std_logic;
    out_pos : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal pos0, pos1 : std_logic;
begin
  
  -- Minimal SOP: out_sop = c&d | ~a&~b&c
  out_sop <= (c and d) or ((not a) and (not b) and c);
  
  -- Minimal POS intermediate calculations
  pos0 <= c and ((not b) or d) and ((not a) or b);
  pos1 <= c and ((not b) or d) and ((not a) or d);
  
  -- Output POS with don't-care handling
  out_pos <= pos0 when (pos0 = pos1) else '-';

end architecture rtl;