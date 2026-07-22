-- (3) Reference implementation (RefModule)
-- Reference Module: Sequential Counter with Conditional Load/Reset
-- When a=1: load q with 4
-- When a=0 and q=6: reset q to 0
-- Otherwise: increment q by 1
-- All operations are synchronous on rising edge of clk

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk : in  std_logic;
    a   : in  std_logic;
    q   : out std_logic_vector(2 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : unsigned(2 downto 0) := (others => '0');
begin
  
  q <= std_logic_vector(q_reg);
  
  -- Matches Verilog:
  -- always @(posedge clk)
  --   if (a)
  --     q <= 4;
  --   else if (q == 6)
  --     q <= 0;
  --   else
  --     q <= q + 1'b1;
  process(clk)
  begin
    if rising_edge(clk) then
      if a = '1' then
        q_reg <= to_unsigned(4, 3);
      elsif q_reg = 6 then
        q_reg <= to_unsigned(0, 3);
      else
        q_reg <= q_reg + 1;
      end if;
    end if;
  end process;

end architecture rtl;