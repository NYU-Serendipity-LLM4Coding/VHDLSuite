-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement bit relationship logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in     : in  std_logic_vector(3 downto 0);
    out_both      : out std_logic_vector(2 downto 0);
    out_any       : out std_logic_vector(3 downto 1);
    out_different : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- out_both[i] indicates if both in[i] and in[i+1] are '1'
  out_both <= signal_in(2 downto 0) and signal_in(3 downto 1);
  
  -- out_any[i] indicates if either in[i] or in[i-1] are '1'
  out_any <= signal_in(2 downto 0) or signal_in(3 downto 1);
  
  -- out_different[i] indicates if in[i] differs from in[(i+1) mod 4]
  -- Wrapping: in[3]'s left neighbor is in[0]
  out_different <= signal_in xor (signal_in(0) & signal_in(3 downto 1));

end architecture rtl;