-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 256-to-1 Multiplexer (4-bit wide)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(1023 downto 0);
    sel        : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal base_index : integer range 0 to 1023;
begin
  
  -- Calculate base index: sel * 4
  base_index <= to_integer(unsigned(sel)) * 4;
  
  -- Extract 4 bits starting from base_index
  signal_out <= signal_in(base_index + 3 downto base_index);

end architecture rtl;