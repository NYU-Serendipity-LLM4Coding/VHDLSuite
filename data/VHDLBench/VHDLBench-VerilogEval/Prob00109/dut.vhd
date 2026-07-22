-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Moore state machine with asynchronous reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    areset     : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (A, B);
  signal state : state_type;
  signal next_state : state_type;
  
begin
  
  -- Combinational next state logic
  next_state_logic : process(state, signal_in)
  begin
    case state is
      when A =>
        if signal_in = '1' then
          next_state <= A;
        else
          next_state <= B;
        end if;
        
      when B =>
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
    end case;
  end process;
  
  -- Sequential state register with asynchronous reset
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= B;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic
  signal_out <= '1' when (state = B) else '0';

end architecture rtl;