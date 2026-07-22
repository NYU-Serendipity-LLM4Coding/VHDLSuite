-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-bit shift register with active-low synchronous reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    resetn     : in  std_logic;
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal sr : std_logic_vector(3 downto 0) := "0000";
begin
  
  signal_out <= sr(3);
  
  process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        sr <= (others => '0');
      else
        sr <= sr(2 downto 0) & signal_in;
      end if;
    end if;
  end process;

end architecture rtl;