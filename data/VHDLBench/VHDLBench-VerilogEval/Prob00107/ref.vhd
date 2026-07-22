-- (3) Reference implementation (RefModule)
-- Reference Module: Two-State Moore FSM
-- States: A (out=0), B (out=1)
-- Synchronous reset to state B
-- State transitions based on input 'in'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk          : in  std_logic;
    signal_in    : in  std_logic;
    signal_reset : in  std_logic;
    signal_out   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameter A=0, B=1)
  type state_type is (A, B);
  signal state : state_type;
  signal next_state : state_type;
  
begin
  
  -- Combinational next-state logic
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
  
  -- Sequential state register with synchronous reset
  -- Matches Verilog: always @(posedge clk) begin if (reset) state <= B; else state <= next; end
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if signal_reset = '1' then
        state <= B;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Output logic (Moore machine - output depends only on state)
  -- Matches Verilog: assign out = (state==B);
  signal_out <= '1' when state = B else '0';

end architecture rtl;