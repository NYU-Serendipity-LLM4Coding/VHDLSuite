-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Dual-edge triggered flip-flop behavior

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal qp : std_logic := '0';
  signal qn : std_logic := '0';
begin
  
  -- Capture on positive edge
  process(clk)
  begin
    if rising_edge(clk) then
      qp <= d;
    end if;
  end process;
  
  -- Capture on negative edge
  process(clk)
  begin
    if falling_edge(clk) then
      qn <= d;
    end if;
  end process;
  
  -- Mux based on clock level
  process(clk, qp, qn)
  begin
    if clk = '1' then
      q <= qp;
    else
      q <= qn;
    end if;
  end process;

end architecture rtl;