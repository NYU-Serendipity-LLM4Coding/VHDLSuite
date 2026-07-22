-- (3) Reference implementation (RefModule)
-- Reference Module: Two-Bit Saturating Counter
-- Asynchronous reset to 2'b01 (weakly not-taken)
-- Increments (saturates at 3) when train_valid=1 and train_taken=1
-- Decrements (saturates at 0) when train_valid=1 and train_taken=0
-- Holds value when train_valid=0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk         : in  std_logic;
    areset      : in  std_logic;
    train_valid : in  std_logic;
    train_taken : in  std_logic;
    state       : out std_logic_vector(1 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal state_reg : unsigned(1 downto 0) := "01";
begin
  
  state <= std_logic_vector(state_reg);
  
  -- Matches Verilog: always @(posedge clk, posedge areset)
  process(clk, areset)
  begin
    if areset = '1' then
      -- Asynchronous reset to 1 (2'b01)
      state_reg <= "01";
    elsif rising_edge(clk) then
      if train_valid = '1' then
        -- Increment if not saturated and train_taken
        if state_reg < 3 and train_taken = '1' then
          state_reg <= state_reg + 1;
        -- Decrement if not at minimum and not train_taken
        elsif state_reg > 0 and train_taken = '0' then
          state_reg <= state_reg - 1;
        end if;
      end if;
      -- else: hold value when train_valid = 0
    end if;
  end process;

end architecture rtl;