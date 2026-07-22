-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Split 16-bit word into high and low bytes

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in : in  std_logic_vector(15 downto 0);
    out_hi    : out std_logic_vector(7 downto 0);
    out_lo    : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Split input into high and low bytes
  out_hi <= signal_in(15 downto 8);  -- Upper byte [15:8]
  out_lo <= signal_in(7 downto 0);   -- Lower byte [7:0]

end architecture rtl;