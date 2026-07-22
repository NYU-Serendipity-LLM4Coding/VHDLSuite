-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Bit reversal of 100-bit input vector

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(99 downto 0);
    signal_out : out std_logic_vector(99 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Reverse the bit order
  process(signal_in)
  begin
    for i in 0 to 99 loop
      signal_out(i) <= signal_in(99 - i);
    end loop;
  end process;

end architecture rtl;