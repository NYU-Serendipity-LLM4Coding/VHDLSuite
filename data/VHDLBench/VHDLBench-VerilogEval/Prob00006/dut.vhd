-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit vector bit reversal

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Reverse bit ordering: in[7:0] -> out[0:7]
  signal_out(0) <= signal_in(7);
  signal_out(1) <= signal_in(6);
  signal_out(2) <= signal_in(5);
  signal_out(3) <= signal_in(4);
  signal_out(4) <= signal_in(3);
  signal_out(5) <= signal_in(2);
  signal_out(6) <= signal_in(1);
  signal_out(7) <= signal_in(0);

end architecture rtl;