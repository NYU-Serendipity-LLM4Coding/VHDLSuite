-- (3) Reference implementation (RefModule)
-- Reference Module: JK Flip-Flop
-- Truth table:
--   J | K | Q
--   0 | 0 | Qold (hold)
--   0 | 1 | 0    (reset)
--   1 | 0 | 1    (set)
--   1 | 1 | ~Qold (toggle)
-- Implementation: Q <= j&~Q | ~k&Q

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    j   : in  std_logic;
    k   : in  std_logic;
    Q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal Q_reg : std_logic := '0';
begin
  
  Q <= Q_reg;
  
  -- Matches Verilog: always @(posedge clk) Q <= j&~Q | ~k&Q;
  process(clk)
  begin
    if rising_edge(clk) then
      Q_reg <= (j and not Q_reg) or (not k and Q_reg);
    end if;
  end process;

end architecture rtl;