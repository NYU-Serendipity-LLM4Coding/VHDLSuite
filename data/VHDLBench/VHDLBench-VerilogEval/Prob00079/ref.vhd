-- (3) Reference implementation (RefModule)
-- Reference Module: One-Hot State Machine (Combinational Logic Only)
-- State encoding: A=0001, B=0010, C=0100, D=1000
-- Implements state transition and output logic
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic;
    state      : in  std_logic_vector(3 downto 0);
    next_state : out std_logic_vector(3 downto 0);
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- State bit indices (matches Verilog parameters)
  constant A : integer := 0;
  constant B : integer := 1;
  constant C : integer := 2;
  constant D : integer := 3;
begin
  
  -- Matches Verilog: assign next_state[A] = (state[A] | state[C]) & ~in;
  next_state(A) <= (state(A) or state(C)) and (not signal_in);
  
  -- Matches Verilog: assign next_state[B] = (state[A] | state[B] | state[D]) & in;
  next_state(B) <= (state(A) or state(B) or state(D)) and signal_in;
  
  -- Matches Verilog: assign next_state[C] = (state[B] | state[D]) & ~in;
  next_state(C) <= (state(B) or state(D)) and (not signal_in);
  
  -- Matches Verilog: assign next_state[D] = state[C] & in;
  next_state(D) <= state(C) and signal_in;
  
  -- Matches Verilog: assign out = (state[D]);
  signal_out <= state(D);

end architecture rtl;