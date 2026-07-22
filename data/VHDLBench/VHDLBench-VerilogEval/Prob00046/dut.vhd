-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 8-bit D flip-flops with synchronous reset to 0x34
-- Triggered on negative clock edge

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
  signal q_reg : std_logic_vector(7 downto 0) := x"00";
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if falling_edge(clk) then
      if reset = '1' then
        q_reg <= x"34";
      else
        q_reg <= d;
      end if;
    end if;
  end process;

end architecture rtl;