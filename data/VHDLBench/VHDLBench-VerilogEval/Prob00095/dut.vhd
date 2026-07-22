-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: FSM that asserts shift_ena for exactly 4 cycles after reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    shift_ena : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  type state_type is (B0, B1, B2, B3, Done);
  
  signal state : state_type;
  signal next_state : state_type;
  
begin

  -- Combinational next-state logic
  next_state_logic : process(state)
  begin
    case state is
      when B0   => next_state <= B1;
      when B1   => next_state <= B2;
      when B2   => next_state <= B3;
      when B3   => next_state <= Done;
      when Done => next_state <= Done;
    end case;
  end process;
  
  -- Sequential state register with synchronous reset
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= B0;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Output logic
  shift_ena <= '1' when (state = B0 or state = B1 or state = B2 or state = B3) else '0';

end architecture rtl;