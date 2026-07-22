-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Moore state machine with states OFF/ON

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    j          : in  std_logic;
    k          : in  std_logic;
    reset      : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (A, B);
  signal state : state_type := A;
  signal next_state : state_type;
  
begin
  
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
  
  signal_out <= '1' when (state = B) else '0';

end architecture rtl;