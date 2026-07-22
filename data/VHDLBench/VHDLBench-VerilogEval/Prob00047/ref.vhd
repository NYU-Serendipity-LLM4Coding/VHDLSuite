-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit D Flip-Flop with Async Reset
-- Active-high asynchronous reset, resets to 0
-- Positive edge triggered
-- Matches Verilog: always @(posedge clk, posedge areset)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    d      : in  std_logic_vector(7 downto 0);
    areset : in  std_logic;
    q      : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog:
  -- always @(posedge clk, posedge areset)
  --   if (areset) q <= 0;
  --   else q <= d;
  process(clk, areset)
  begin
    if areset = '1' then
      q <= (others => '0');  -- Asynchronous reset to 0
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;