-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement K-map logic using mux inputs

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    c      : in  std_logic;
    d      : in  std_logic;
    mux_in : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  mux_in(0) <= c or d;
  mux_in(1) <= '0';
  mux_in(2) <= not d;
  mux_in(3) <= c and d;

end architecture rtl;