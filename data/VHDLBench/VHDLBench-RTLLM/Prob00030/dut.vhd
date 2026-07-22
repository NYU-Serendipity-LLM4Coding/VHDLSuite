-- (2) DUT implementation (right_shifter)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity right_shifter is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic_vector(7 downto 0)
  );
end entity right_shifter;

architecture rtl of right_shifter is
  signal q_reg : std_logic_vector(7 downto 0) := (others => '0');
begin

  -- Right shift process
  shift_proc : process(clk)
  begin
    if rising_edge(clk) then
      -- Right shift by 1 bit
      q_reg <= d & q_reg(7 downto 1);
    end if;
  end process;
  
  -- Output assignment
  q <= q_reg;
  
end architecture rtl;