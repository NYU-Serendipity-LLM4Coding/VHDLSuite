-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 3-bit population count circuit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(2 downto 0);
    signal_out : out std_logic_vector(1 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal count : unsigned(1 downto 0);
begin
  
  -- Population count: sum the three bits
  -- FIXED: Use character '0' not string "0" in concatenation
  count <= resize(unsigned'('0' & signal_in(0)), 2) + 
           resize(unsigned'('0' & signal_in(1)), 2) + 
           resize(unsigned'('0' & signal_in(2)), 2);
  
  signal_out <= std_logic_vector(count);

end architecture rtl;