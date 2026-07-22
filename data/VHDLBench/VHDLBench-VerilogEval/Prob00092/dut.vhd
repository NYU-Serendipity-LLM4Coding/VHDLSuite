-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement neighbor comparison logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in     : in  std_logic_vector(99 downto 0);
    out_both      : out std_logic_vector(98 downto 0);
    out_any       : out std_logic_vector(99 downto 1);
    out_different : out std_logic_vector(99 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- out_both[i] = in[i] AND in[i+1]
  out_both <= signal_in(98 downto 0) and signal_in(99 downto 1);
  
  -- out_any[i] = in[i] OR in[i-1]
  out_any <= signal_in(99 downto 1) or signal_in(98 downto 0);
  
  -- out_different[i] = in[i] XOR in[(i+1) mod 100]
  out_different <= signal_in xor (signal_in(0) & signal_in(99 downto 1));

end architecture rtl;