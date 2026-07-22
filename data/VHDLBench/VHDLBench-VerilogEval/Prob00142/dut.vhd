-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Lemmings state machine with asynchronous reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    areset     : in  std_logic;
    bump_left  : in  std_logic;
    bump_right : in  std_logic;
    ground     : in  std_logic;
    walk_left  : out std_logic;
    walk_right : out std_logic;
    aaah       : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_t is (WL, WR, FALLL, FALLR);
  signal state : state_t;
  signal next_state : state_t;
  
begin

  -- Combinational next-state logic
  process(state, bump_left, bump_right, ground)
  begin
    case state is
      when WL =>
        if ground = '1' then
          if bump_left = '1' then
            next_state <= WR;
          else
            next_state <= WL;
          end if;
        else
          next_state <= FALLL;
        end if;
        
      when WR =>
        if ground = '1' then
          if bump_right = '1' then
            next_state <= WL;
          else
            next_state <= WR;
          end if;
        else
          next_state <= FALLR;
        end if;
        
      when FALLL =>
        if ground = '1' then
          next_state <= WL;
        else
          next_state <= FALLL;
        end if;
        
      when FALLR =>
        if ground = '1' then
          next_state <= WR;
        else
          next_state <= FALLR;
        end if;
    end case;
  end process;
  
  -- State register with asynchronous reset
  process(clk, areset)
  begin
    if areset = '1' then
      state <= WL;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic
  walk_left  <= '1' when (state = WL) else '0';
  walk_right <= '1' when (state = WR) else '0';
  aaah       <= '1' when (state = FALLL or state = FALLR) else '0';

end architecture rtl;