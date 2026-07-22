-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Lemmings FSM with asynchronous reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    areset     : in  std_logic;
    bump_left  : in  std_logic;
    bump_right : in  std_logic;
    walk_left  : out std_logic;
    walk_right : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_t is (WL, WR);
  signal state : state_t;
  signal next_state : state_t;
  
begin
  
  -- Next-state logic
  next_state_logic : process(state, bump_left, bump_right)
  begin
    case state is
      when WL =>
        if bump_left = '1' then
          next_state <= WR;
        else
          next_state <= WL;
        end if;
        
      when WR =>
        if bump_right = '1' then
          next_state <= WL;
        else
          next_state <= WR;
        end if;
    end case;
  end process;
  
  -- State register with asynchronous reset
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= WL;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic
  walk_left  <= '1' when state = WL else '0';
  walk_right <= '1' when state = WR else '0';

end architecture rtl;