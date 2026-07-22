-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Serial Protocol Receiver FSM
-- State name changes: DONE -> DONE_STATE (conflicts with port name 'done')

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic;
    reset     : in  std_logic;
    done      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (B0, B1, B2, B3, B4, B5, B6, B7, START, STOP, DONE_STATE, ERR);
  
  signal state : state_type;
  signal next_state : state_type;
  
begin

  next_state_logic : process(state, signal_in)
  begin
    case state is
      when START =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= B0;
        end if;
        
      when B0 =>
        next_state <= B1;
        
      when B1 =>
        next_state <= B2;
        
      when B2 =>
        next_state <= B3;
        
      when B3 =>
        next_state <= B4;
        
      when B4 =>
        next_state <= B5;
        
      when B5 =>
        next_state <= B6;
        
      when B6 =>
        next_state <= B7;
        
      when B7 =>
        next_state <= STOP;
        
      when STOP =>
        if signal_in = '1' then
          next_state <= DONE_STATE;
        else
          next_state <= ERR;
        end if;
        
      when DONE_STATE =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= B0;
        end if;
        
      when ERR =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= ERR;
        end if;
        
      when others =>
        next_state <= START;
    end case;
  end process;
  
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= START;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  done <= '1' when state = DONE_STATE else '0';

end architecture rtl;