-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Timer FSM

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk           : in  std_logic;
    reset         : in  std_logic;
    data          : in  std_logic;
    shift_ena     : out std_logic;
    counting      : out std_logic;
    done_counting : in  std_logic;
    done          : out std_logic;
    ack           : in  std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type States is (S, S1, S11, S110, B0, B1, B2, B3, Count, Wait_State);
  signal state, next_state : States;
  
begin

  next_state_logic : process(state, data, done_counting, ack)
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
          next_state <= B0;
        else
          next_state <= S;
        end if;
        
      when B0 =>
        next_state <= B1;
        
      when B1 =>
        next_state <= B2;
        
      when B2 =>
        next_state <= B3;
        
      when B3 =>
        next_state <= Count;
        
      when Count =>
        if done_counting = '1' then
          next_state <= Wait_State;
        else
          next_state <= Count;
        end if;
        
      when Wait_State =>
        if ack = '1' then
          next_state <= S;
        else
          next_state <= Wait_State;
        end if;
        
      when others =>
        next_state <= S;
    end case;
  end process;
  
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
  
  output_logic : process(state)
  begin
    shift_ena <= '0';
    counting <= '0';
    done <= '0';
    
    if state = B0 or state = B1 or state = B2 or state = B3 then
      shift_ena <= '1';
    end if;
    
    if state = Count then
      counting <= '1';
    end if;
    
    if state = Wait_State then
      done <= '1';
    end if;
  end process;

end architecture rtl;