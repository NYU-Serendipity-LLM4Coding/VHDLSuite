-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Byte order reversal of 32-bit vector

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(31 downto 0);
    signal_out : out std_logic_vector(31 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Reverse byte order: {byte0, byte1, byte2, byte3} -> {byte3, byte2, byte1, byte0}
  signal_out <= signal_in(7 downto 0) & signal_in(15 downto 8) & 
                signal_in(23 downto 16) & signal_in(31 downto 24);

end architecture rtl;