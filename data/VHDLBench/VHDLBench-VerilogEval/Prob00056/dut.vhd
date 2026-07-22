-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: JK Flip-Flop with specified truth table

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    j   : in  std_logic;
    k   : in  std_logic;
    Q   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal Q_reg : std_logic := '0';
begin
  
  Q <= Q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      Q_reg <= (j and not Q_reg) or (not k and Q_reg);
    end if;
  end process;

end architecture rtl;