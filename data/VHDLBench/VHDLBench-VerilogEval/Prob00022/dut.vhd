-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement 2-to-1 multiplexer

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    sel        : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- 2-to-1 multiplexer: select b when sel=1, otherwise select a
  signal_out <= b when sel = '1' else a;

end architecture rtl;