-- (4) DUT implementation (TopModule)
-- User's FSM design under test
-- Must implement the same state machine behavior

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    w     : in  std_logic;
    z     : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (A, B, C, D, E, F);
  signal state : state_type := A;
  signal next_state : state_type;
  
begin

  -- State register with synchronous reset
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Next state logic
  next_state_logic : process(state, w)
  begin
    case state is
      when A =>
        if w = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when B =>
        if w = '1' then
          next_state <= C;
        else
          next_state <= D;
        end if;
        
      when C =>
        if w = '1' then
          next_state <= E;
        else
          next_state <= D;
        end if;
        
      when D =>
        if w = '1' then
          next_state <= F;
        else
          next_state <= A;
        end if;
        
      when E =>
        if w = '1' then
          next_state <= E;
        else
          next_state <= D;
        end if;
        
      when F =>
        if w = '1' then
          next_state <= C;
        else
          next_state <= D;
        end if;
        
      when others =>
        next_state <= A;
    end case;
  end process;
  
  -- Output logic
  z <= '1' when (state = E or state = F) else '0';

end architecture rtl;