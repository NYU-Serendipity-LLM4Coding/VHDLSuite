-- (3) Reference implementation (RefModule)
-- Reference Module: Branch History Register with Misprediction Rollback
-- 32-bit shift register for branch prediction history
-- Supports rollback on misprediction
-- Asynchronous reset to zero

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
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
end entity RefModule;

architecture rtl of RefModule is
  signal history_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
  
  predict_history <= history_reg;
  
  -- Matches Verilog: always@(posedge clk, posedge areset)
  process(clk, areset)
  begin
    if areset = '1' then
      -- Asynchronous reset
      history_reg <= (others => '0');
    elsif rising_edge(clk) then
      -- Priority: misprediction > prediction
      if train_mispredicted = '1' then
        -- Matches Verilog: {train_history, train_taken}
        -- Shift train_history left by 1, insert train_taken at LSB
        history_reg <= train_history(30 downto 0) & train_taken;
      elsif predict_valid = '1' then
        -- Matches Verilog: {predict_history, predict_taken}
        -- Shift history left by 1, insert predict_taken at LSB
        history_reg <= history_reg(30 downto 0) & predict_taken;
      end if;
    end if;
  end process;

end architecture rtl;