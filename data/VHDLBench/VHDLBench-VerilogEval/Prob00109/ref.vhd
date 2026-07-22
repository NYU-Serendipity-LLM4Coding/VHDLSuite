-- (3) Reference implementation (RefModule)
-- Reference Module: Moore State Machine
-- Two states: A (output 0) and B (output 1)
-- State transitions:
--   A --0--> B, A --1--> A
--   B --0--> A, B --1--> B
-- Asynchronous reset to state B
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    areset     : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog: parameter A=0, B=1)
  type state_type is (A, B);
  
  signal state : state_type;
  signal next_state : state_type;
  
begin
  
  -- Combinational next state logic
  -- Matches Verilog: always_comb begin case (state) ... endcase end
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
  -- Matches Verilog: always @(posedge clk, posedge areset)
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= B;  -- Asynchronous reset to state B
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic (Moore machine: output depends only on state)
  -- Matches Verilog: assign out = (state==B);
  signal_out <= '1' when (state = B) else '0';

end architecture rtl;