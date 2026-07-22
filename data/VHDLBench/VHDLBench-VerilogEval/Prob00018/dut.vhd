-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 256-to-1 multiplexer
-- sel=0 selects in[0], sel=1 selects in[1], etc.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(255 downto 0);
    sel        : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- 256-to-1 multiplexer implementation
  signal_out <= signal_in(to_integer(unsigned(sel)));

end architecture rtl;