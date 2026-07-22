-- (3) Reference implementation (RefModule)
-- Reference Module: Shift Register Stage with Load and Enable
-- Priority: L (load) > E (enable)
-- When L=1: Q <= R (load value)
-- When L=0, E=1: Q <= w (shift in)
-- When L=0, E=0: Q holds current value

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    w   : in  std_logic;
    R   : in  std_logic;
    E   : in  std_logic;
    L   : in  std_logic;
    Q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal Q_reg : std_logic;
begin
  
  Q <= Q_reg;
  
  -- Matches Verilog:
  -- always @(posedge clk)
  --   if (L)
  --     Q <= R;
  --   else if (E)
  --     Q <= w;
  process(clk)
  begin
    if rising_edge(clk) then
      if L = '1' then
        Q_reg <= R;
      elsif E = '1' then
        Q_reg <= w;
      end if;
      -- Note: When L=0 and E=0, Q_reg holds its value (implicit)
    end if;
  end process;

end architecture rtl;