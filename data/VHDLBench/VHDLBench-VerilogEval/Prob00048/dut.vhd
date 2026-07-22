-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: D Flip-Flop with Active High Synchronous Reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    r   : in  std_logic;
    q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(clk)
  begin
    if rising_edge(clk) then
      if r = '1' then
        q <= '0';
      else
        q <= d;
      end if;
    end if;
  end process;

end architecture rtl;