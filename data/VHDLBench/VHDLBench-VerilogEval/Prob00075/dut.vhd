-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Two-bit saturating counter with async reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk         : in  std_logic;
    areset      : in  std_logic;
    train_valid : in  std_logic;
    train_taken : in  std_logic;
    state       : out std_logic_vector(1 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal state_reg : unsigned(1 downto 0) := "01";
begin
  
  state <= std_logic_vector(state_reg);
  
  process(clk, areset)
  begin
    if areset = '1' then
      state_reg <= "01";
    elsif rising_edge(clk) then
      if train_valid = '1' then
        if state_reg < 3 and train_taken = '1' then
          state_reg <= state_reg + 1;
        elsif state_reg > 0 and train_taken = '0' then
          state_reg <= state_reg - 1;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;