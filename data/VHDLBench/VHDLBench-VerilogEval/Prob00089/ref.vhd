-- (3) Reference implementation (RefModule)
-- Reference Module: 2's Complement Moore FSM
-- Three-state Moore machine with asynchronous reset
-- States: A (initial), B (copying 1s), C (inverting)
-- Output z = '1' when in state C

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    areset : in  std_logic;
    x      : in  std_logic;
    z      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  type state_type is (A, B, C);
  signal state : state_type;
  
begin
  
  -- State machine with asynchronous reset
  -- Matches Verilog: always @(posedge clk, posedge areset)
  process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      case state is
        when A =>
          if x = '1' then
            state <= C;
          else
            state <= A;
          end if;
          
        when B =>
          if x = '1' then
            state <= B;
          else
            state <= C;
          end if;
          
        when C =>
          if x = '1' then
            state <= B;
          else
            state <= C;
          end if;
      end case;
    end if;
  end process;
  
  -- Output logic (Moore machine)
  -- Matches Verilog: assign z = (state == C);
  z <= '1' when state = C else '0';

end architecture rtl;