-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Down-counter timer with load control

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(9 downto 0);
    tc   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal count_value : unsigned(9 downto 0) := (others => '0');
begin
  
  tc <= '1' when count_value = 0 else '0';
  
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        count_value <= unsigned(data);
      elsif count_value /= 0 then
        count_value <= count_value - 1;
      end if;
    end if;
  end process;

end architecture rtl;