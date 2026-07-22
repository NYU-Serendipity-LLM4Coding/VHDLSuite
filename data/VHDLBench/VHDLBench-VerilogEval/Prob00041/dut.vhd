-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit D Flip-Flop with Synchronous Active-High Reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    d     : in  std_logic_vector(7 downto 0);
    reset : in  std_logic;
    q     : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        q_reg <= (others => '0');
      else
        q_reg <= d;
      end if;
    end if;
  end process;

end architecture rtl;