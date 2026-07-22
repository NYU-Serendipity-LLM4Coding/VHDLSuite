-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit edge detector

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic_vector(7 downto 0);
    anyedge   : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal d_last : std_logic_vector(7 downto 0);
begin

  process(clk)
  begin
    if rising_edge(clk) then
      d_last  <= signal_in;
      anyedge <= signal_in xor d_last;
    end if;
  end process;

end architecture rtl;