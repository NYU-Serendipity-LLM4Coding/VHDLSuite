-- (3) Reference implementation (RefModule)
-- Reference Module: Shift Enable FSM
-- FSM with 5 states (B0, B1, B2, B3, Done)
-- Asserts shift_ena for exactly 4 cycles after reset, then stays low
-- Reset is active high synchronous

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    shift_ena : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  -- parameter B0=0, B1=1, B2=2, B3=3, Done=4;
  type state_type is (B0, B1, B2, B3, Done);
  
  signal state : state_type;
  signal next_state : state_type;
  
begin

  -- Combinational next-state logic
  -- Matches Verilog: always_comb begin case (state) ... endcase end
  next_state_logic : process(state)
  begin
    case state is
      when B0   => next_state <= B1;
      when B1   => next_state <= B2;
      when B2   => next_state <= B3;
      when B3   => next_state <= Done;
      when Done => next_state <= Done;
    end case;
  end process;
  
  -- Sequential state register with synchronous reset
  -- Matches Verilog: always @(posedge clk) if (reset) state <= B0; else state <= next;
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= B0;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Output logic
  -- Matches Verilog: assign shift_ena = (state == B0 || state == B1 || state == B2 || state == B3);
  shift_ena <= '1' when (state = B0 or state = B1 or state = B2 or state = B3) else '0';

end architecture rtl;