-- (3) Reference implementation (RefModule)
-- Reference Module: One-Hot State Machine Logic
-- Implements next state logic and outputs for 10-state FSM
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in  : in  std_logic;
    state      : in  std_logic_vector(9 downto 0);
    next_state : out std_logic_vector(9 downto 0);
    out1       : out std_logic;
    out2       : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Helper signal for reduction OR of state[4:0]
  signal or_state_4_0 : std_logic;
begin
  
  -- Matches Verilog: assign out1 = state[8] | state[9];
  out1 <= state(8) or state(9);
  
  -- Matches Verilog: assign out2 = state[7] | state[9];
  out2 <= state(7) or state(9);
  
  -- Reduction OR for state[4:0]
  -- Matches Verilog: |state[4:0]
  or_state_4_0 <= state(0) or state(1) or state(2) or state(3) or state(4);
  
  -- Next state logic (combinational)
  -- Matches Verilog assign statements
  
  -- next_state[0] = !in && (|state[4:0] | state[7] | state[8] | state[9]);
  next_state(0) <= (not signal_in) and 
                   (or_state_4_0 or state(7) or state(8) or state(9));
  
  -- next_state[1] = in && (state[0] | state[8] | state[9]);
  next_state(1) <= signal_in and (state(0) or state(8) or state(9));
  
  -- next_state[2] = in && state[1];
  next_state(2) <= signal_in and state(1);
  
  -- next_state[3] = in && state[2];
  next_state(3) <= signal_in and state(2);
  
  -- next_state[4] = in && state[3];
  next_state(4) <= signal_in and state(3);
  
  -- next_state[5] = in && state[4];
  next_state(5) <= signal_in and state(4);
  
  -- next_state[6] = in && state[5];
  next_state(6) <= signal_in and state(5);
  
  -- next_state[7] = in && (state[6] | state[7]);
  next_state(7) <= signal_in and (state(6) or state(7));
  
  -- next_state[8] = !in && state[5];
  next_state(8) <= (not signal_in) and state(5);
  
  -- next_state[9] = !in && state[6];
  next_state(9) <= (not signal_in) and state(6);

end architecture rtl;