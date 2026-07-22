-- (3) Reference implementation (RefModule)
-- Reference Module: Decade Counter (1 to 10)
-- Synchronous reset, resets to 1
-- Counts from 1 to 10, wraps back to 1
-- Matches Verilog reference implementation

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
  signal q_reg : unsigned(3 downto 0) := to_unsigned(1, 4);
begin
  
  q <= std_logic_vector(q_reg);
  
  -- Matches Verilog: always @(posedge clk)
  --   if (reset || q == 10)
  --     q <= 1;
  --   else
  --     q <= q+1;
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or q_reg = 10 then
        q_reg <= to_unsigned(1, 4);
      else
        q_reg <= q_reg + 1;
      end if;
    end if;
  end process;

end architecture rtl;