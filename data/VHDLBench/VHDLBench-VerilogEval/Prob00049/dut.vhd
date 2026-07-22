-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: D Flip-Flop with Asynchronous Reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    ar  : in  std_logic;  -- Asynchronous reset
    q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- D flip-flop with asynchronous reset
  -- ar has priority and acts immediately
  process(clk, ar)
  begin
    if ar = '1' then
      q <= '0';
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;