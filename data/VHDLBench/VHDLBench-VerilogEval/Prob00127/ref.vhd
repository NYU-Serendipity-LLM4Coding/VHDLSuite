-- (3) Reference implementation (RefModule)
-- Reference Module: Lemmings FSM
-- Two-state Moore FSM: Walk Left (WL) or Walk Right (WR)
-- Asynchronous active-high reset to WL state
-- State transitions on bump_left/bump_right

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    areset     : in  std_logic;
    bump_left  : in  std_logic;
    bump_right : in  std_logic;
    walk_left  : out std_logic;
    walk_right : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog: parameter WL=0, WR=1)
  type state_t is (WL, WR);
  signal state : state_t;
  signal next_state : state_t;
  
begin
  
  -- Combinational next-state logic
  -- Matches Verilog: always_comb begin ... end
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
  
  -- Sequential state register with asynchronous reset
  -- Matches Verilog: always @(posedge clk, posedge areset)
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= WL;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic (Moore machine - outputs depend only on state)
  -- Matches Verilog: assign walk_left = (state==WL);
  walk_left  <= '1' when state = WL else '0';
  walk_right <= '1' when state = WR else '0';

end architecture rtl;