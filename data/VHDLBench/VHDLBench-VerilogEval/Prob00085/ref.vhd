-- (3) Reference implementation (RefModule)
-- Reference Module: 4-bit Shift Register (right shift)
-- Features:
--   - Asynchronous active-high reset (areset)
--   - Synchronous load (priority over enable)
--   - Synchronous right shift enable (ena)
-- Priority: areset > load > ena

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    areset : in  std_logic;
    load   : in  std_logic;
    ena    : in  std_logic;
    data   : in  std_logic_vector(3 downto 0);
    q      : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(3 downto 0) := "0000";
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk, posedge areset)
  -- Asynchronous reset with synchronous load and enable
  process(clk, areset)
  begin
    if areset = '1' then
      -- Asynchronous reset
      q_reg <= "0000";
    elsif rising_edge(clk) then
      if load = '1' then
        -- Load has priority
        q_reg <= data;
      elsif ena = '1' then
        -- Right shift: q[3:1] -> q[2:0], q[3] becomes 0
        -- Matches Verilog: q <= q[3:1];
        q_reg <= '0' & q_reg(3 downto 1);
      end if;
    end if;
  end process;

end architecture rtl;