-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Moore state machine with async reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    j          : in  std_logic;
    k          : in  std_logic;
    areset     : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (A, B);
  signal state : state_type := A;
  signal next_state : state_type;
  
begin
  
  -- Next state logic
  next_state_logic : process(state, j, k)
  begin
    case state is
      when A =>
        if j = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
      
      when B =>
        if k = '1' then
          next_state <= A;
        else
          next_state <= B;
        end if;
    end case;
  end process;
  
  -- State register with asynchronous reset
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output (Moore: depends only on state)
  signal_out <= '1' when (state = B) else '0';

end architecture rtl;