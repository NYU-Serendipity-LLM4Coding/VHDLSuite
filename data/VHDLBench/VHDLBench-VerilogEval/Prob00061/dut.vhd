-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Shift register stage with load and enable control

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    w   : in  std_logic;
    R   : in  std_logic;
    E   : in  std_logic;
    L   : in  std_logic;
    Q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal Q_reg : std_logic;
begin
  
  Q <= Q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if L = '1' then
        Q_reg <= R;
      elsif E = '1' then
        Q_reg <= w;
      end if;
    end if;
  end process;

end architecture rtl;