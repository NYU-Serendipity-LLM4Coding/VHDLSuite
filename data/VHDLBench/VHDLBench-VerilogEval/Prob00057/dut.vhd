-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement the Karnaugh map circuit
-- K-map for reference:
--              ab
--   cd   00  01  11  10
--   00 | 1 | 1 | 0 | 1 |
--   01 | 1 | 0 | 0 | 1 |
--   11 | 0 | 1 | 1 | 1 |
--   10 | 1 | 1 | 0 | 0 |

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    d          : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Implementation of the Karnaugh map
  -- Simplified boolean expression: (~c & ~b) | (~d & ~a) | (a & c & d) | (b & c & d)
  signal_out <= ((not c) and (not b)) or 
                ((not d) and (not a)) or 
                (a and c and d) or 
                (b and c and d);

end architecture rtl;