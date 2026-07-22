-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-bit shift/counter register

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    shift_ena : in  std_logic;
    count_ena : in  std_logic;
    data      : in  std_logic;
    q         : out std_logic_vector(3 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(3 downto 0) := "0000";
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if shift_ena = '1' then
        -- Shift left, MSB first (data enters at LSB)
        q_reg <= q_reg(2 downto 0) & data;
      elsif count_ena = '1' then
        -- Count down
        q_reg <= std_logic_vector(unsigned(q_reg) - 1);
      end if;
    end if;
  end process;

end architecture rtl;