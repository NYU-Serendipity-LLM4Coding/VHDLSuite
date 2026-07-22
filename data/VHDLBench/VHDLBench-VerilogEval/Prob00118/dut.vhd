-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement branch history register with misprediction handling

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk              : in  std_logic;
    areset           : in  std_logic;
    predict_valid    : in  std_logic;
    predict_taken    : in  std_logic;
    predict_history  : out std_logic_vector(31 downto 0);
    train_mispredicted : in  std_logic;
    train_taken      : in  std_logic;
    train_history    : in  std_logic_vector(31 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal history_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
  
  predict_history <= history_reg;
  
  process(clk, areset)
  begin
    if areset = '1' then
      history_reg <= (others => '0');
    elsif rising_edge(clk) then
      if train_mispredicted = '1' then
        history_reg <= train_history(30 downto 0) & train_taken;
      elsif predict_valid = '1' then
        history_reg <= history_reg(30 downto 0) & predict_taken;
      end if;
    end if;
  end process;

end architecture rtl;