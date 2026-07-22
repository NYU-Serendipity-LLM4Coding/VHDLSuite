-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement 2-to-1 mux with two methods

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    sel_b1     : in  std_logic;
    sel_b2     : in  std_logic;
    out_assign : out std_logic;
    out_always : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Method 1: Concurrent assignment
  out_assign <= b when (sel_b1 = '1' and sel_b2 = '1') else a;
  
  -- Method 2: Process with if statement
  process(a, b, sel_b1, sel_b2)
  begin
    if (sel_b1 = '1' and sel_b2 = '1') then
      out_always <= b;
    else
      out_always <= a;
    end if;
  end process;

end architecture rtl;