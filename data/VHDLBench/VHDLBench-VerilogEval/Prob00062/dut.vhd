-- (4) DUT implementation (TopModule)
-- User's design under test
-- Fixed version of buggy 8-bit 2-to-1 mux

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    sel        : in  std_logic;
    a          : in  std_logic_vector(7 downto 0);
    b          : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Fixed implementation: output should be 8 bits, not 1 bit
  -- Correct mux: sel=1 selects a, sel=0 selects b
  signal_out <= a when sel = '1' else b;

end architecture rtl;