-- (3) Reference implementation (RefModule)
-- Reference Module: 1101 Sequence Detector FSM
-- Detects sequence "1101" and sets start_shifting high permanently until reset
-- Synchronous active-high reset
-- States: S(0), S1(1), S11(2), S110(3), Done(4)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;
    data           : in  std_logic;
    start_shifting : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  type state_type is (S, S1, S11, S110, Done);
  signal state, next_state : state_type;
  
begin
  
  -- Combinational next-state logic
  -- Matches Verilog: always_comb begin case (state) ... endcase end
  next_state_logic : process(state, data)
  begin
    case state is
      when S =>
        if data = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when S1 =>
        if data = '1' then
          next_state <= S11;
        else
          next_state <= S;
        end if;
        
      when S11 =>
        if data = '1' then
          next_state <= S11;
        else
          next_state <= S110;
        end if;
        
      when S110 =>
        if data = '1' then
          next_state <= Done;
        else
          next_state <= S;
        end if;
        
      when Done =>
        next_state <= Done;
        
    end case;
  end process;
  
  -- Sequential state register
  -- Matches Verilog: always @(posedge clk) if (reset) state <= S; else state <= next;
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Output logic
  -- Matches Verilog: assign start_shifting = state == Done;
  start_shifting <= '1' when state = Done else '0';

end architecture rtl;