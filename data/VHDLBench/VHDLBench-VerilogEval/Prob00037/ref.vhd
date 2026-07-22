-- (3) Reference implementation (RefModule)
-- Reference Module: 0-999 Counter with Synchronous Reset
-- Counts from 0 to 999, wraps around to 0
-- Synchronous reset to 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(9 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : unsigned(9 downto 0) := (others => '0');
begin
  
  q <= std_logic_vector(q_reg);
  
  -- Matches Verilog: always @(posedge clk)
  --   if (reset || q == 999) q <= 0;
  --   else q <= q+1;
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or q_reg = 999 then
        q_reg <= (others => '0');
      else
        q_reg <= q_reg + 1;
      end if;
    end if;
  end process;

end architecture rtl;