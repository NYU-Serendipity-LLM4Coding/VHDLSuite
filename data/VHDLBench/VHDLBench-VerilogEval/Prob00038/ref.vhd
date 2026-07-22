-- (3) Reference implementation (RefModule)
-- Reference Module: 4-bit Binary Counter with Synchronous Reset
-- Counts from 0 to 15 (period = 16)
-- Reset is active high and synchronous

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: output reg [3:0] q
  signal q_reg : unsigned(3 downto 0) := (others => '0');
begin
  
  q <= std_logic_vector(q_reg);
  
  -- Matches Verilog: always @(posedge clk)
  --                     if (reset) q <= 0;
  --                     else q <= q+1;
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        q_reg <= (others => '0');
      else
        q_reg <= q_reg + 1;
      end if;
    end if;
  end process;

end architecture rtl;