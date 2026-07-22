-- (3) Reference implementation (RefModule)
-- Reference Module: Moore State Machine (JK-like FSM)
-- Two states (A=OFF, B=ON) with asynchronous reset
-- State transitions controlled by j and k inputs
-- Variable name changes: 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    j          : in  std_logic;
    k          : in  std_logic;
    areset     : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog: parameter A=0, B=1)
  type state_type is (A, B);
  signal state : state_type := A;
  signal next_state : state_type;
  
begin
  
  -- Combinational logic for next state
  -- Matches Verilog: always_comb begin case (state) ... endcase end
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
  
  -- Sequential logic with asynchronous reset
  -- Matches Verilog: always @(posedge clk, posedge areset)
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic (Moore machine: output depends only on state)
  -- Matches Verilog: assign out = (state==B);
  signal_out <= '1' when (state = B) else '0';

end architecture rtl;