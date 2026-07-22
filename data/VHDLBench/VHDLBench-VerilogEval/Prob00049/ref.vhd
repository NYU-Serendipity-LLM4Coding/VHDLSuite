-- (3) Reference implementation (RefModule)
-- Reference Module: D Flip-Flop with Asynchronous Reset
-- Positive edge triggered, asynchronous active-high reset (ar)
-- When ar=1, q is reset to 0 immediately (asynchronous)
-- Otherwise, q captures d on rising edge of clk

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    ar  : in  std_logic;  -- Asynchronous reset
    q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always@(posedge clk or posedge ar)
  -- Asynchronous reset has priority
  process(clk, ar)
  begin
    if ar = '1' then
      -- Asynchronous reset (takes effect immediately)
      q <= '0';
    elsif rising_edge(clk) then
      -- Normal D flip-flop operation on clock edge
      q <= d;
    end if;
  end process;

end architecture rtl;