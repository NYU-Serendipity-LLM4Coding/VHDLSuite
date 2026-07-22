-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement 100-bit 2-to-1 multiplexer

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic_vector(99 downto 0);
    b          : in  std_logic_vector(99 downto 0);
    sel        : in  std_logic;
    signal_out : out std_logic_vector(99 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Select b when sel=1, otherwise select a
  signal_out <= b when sel = '1' else a;

end architecture rtl;