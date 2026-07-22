-- (3) Reference implementation (RefModule)
-- Reference Module: Moore State Machine Next-State Logic
-- One-hot encoded state machine with 10 states
-- State encoding: (S, S1, S11, S110, B0, B1, B2, B3, Count, Wait_State)
-- Implements next-state logic and output logic
-- Note: 'Wait' renamed to 'Wait_State' (VHDL reserved keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    d             : in  std_logic;
    done_counting : in  std_logic;
    ack           : in  std_logic;
    state         : in  std_logic_vector(9 downto 0);  -- one-hot current state
    B3_next       : out std_logic;
    S_next        : out std_logic;
    S1_next       : out std_logic;
    Count_next    : out std_logic;
    Wait_next     : out std_logic;
    done          : out std_logic;
    counting      : out std_logic;
    shift_ena     : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- State bit positions (matches Verilog parameter)
  constant S          : integer := 0;
  constant S1         : integer := 1;
  constant S11        : integer := 2;
  constant S110       : integer := 3;
  constant B0         : integer := 4;
  constant B1         : integer := 5;
  constant B2         : integer := 6;
  constant B3         : integer := 7;
  constant Count      : integer := 8;
  constant Wait_State : integer := 9;  -- Renamed from 'Wait' (VHDL keyword)
  
begin

  -- Next-state logic (matches Verilog assign statements)
  -- B3_next = state[B2]
  B3_next <= state(B2);
  
  -- S_next = state[S]&~d | state[S1]&~d | state[S110]&~d | state[Wait]&ack
  S_next <= (state(S) and not d) or
            (state(S1) and not d) or
            (state(S110) and not d) or
            (state(Wait_State) and ack);
  
  -- S1_next = state[S]&d
  S1_next <= state(S) and d;
  
  -- Count_next = state[B3] | state[Count]&~done_counting
  Count_next <= state(B3) or (state(Count) and not done_counting);
  
  -- Wait_next = state[Count]&done_counting | state[Wait]&~ack
  Wait_next <= (state(Count) and done_counting) or
               (state(Wait_State) and not ack);
  
  -- Output logic
  -- done = state[Wait]
  done <= state(Wait_State);
  
  -- counting = state[Count]
  counting <= state(Count);
  
  -- shift_ena = |state[B3:B0] (reduction OR of bits B0 through B3)
  shift_ena <= state(B0) or state(B1) or state(B2) or state(B3);

end architecture rtl;