-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 1101 sequence detector FSM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;
    data           : in  std_logic;
    start_shifting : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  type state_type is (S, S1, S11, S110, Done);
  signal state, next_state : state_type;
  
begin
  
  -- Combinational next-state logic
  next_state_logic : process(state, data)
  begin
    case state is
      when S =>
        if data = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when S1 =>
        if data = '1' then
          next_state <= S11;
        else
          next_state <= S;
        end if;
        
      when S11 =>
        if data = '1' then
          next_state <= S11;
        else
          next_state <= S110;
        end if;
        
      when S110 =>
        if data = '1' then
          next_state <= Done;
        else
          next_state <= S;
        end if;
        
      when Done =>
        next_state <= Done;
        
    end case;
  end process;
  
  -- Sequential state register with synchronous reset
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Output logic
  start_shifting <= '1' when state = Done else '0';

end architecture rtl;