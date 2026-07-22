-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit to 32-bit sign extension

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(31 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Sign extension: replicate sign bit 24 times, concatenate with input
  signal_out <= (31 downto 8 => signal_in(7)) & signal_in;

end architecture rtl;