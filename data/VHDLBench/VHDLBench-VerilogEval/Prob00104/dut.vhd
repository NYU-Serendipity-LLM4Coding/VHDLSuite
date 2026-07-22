-- (4) DUT implementation (TopModule)
-- User's design under test
-- Submodule for hierarchical design containing flip-flop with 2:1 mux
-- This will be instantiated three times in full_module (not provided)

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk  : in  std_logic;
    L    : in  std_logic;
    q_in : in  std_logic;
    r_in : in  std_logic;
    Q    : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal Q_reg : std_logic := '0';
begin
  
  Q <= Q_reg;
  
  -- Flip-flop with 2:1 mux
  -- When L=1, load r_in; when L=0, load q_in
  process(clk)
  begin
    if rising_edge(clk) then
      if L = '1' then
        Q_reg <= r_in;
      else
        Q_reg <= q_in;
      end if;
    end if;
  end process;

end architecture rtl;