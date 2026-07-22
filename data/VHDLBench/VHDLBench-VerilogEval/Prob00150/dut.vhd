-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Moore state machine next-state and output logic
-- Note: 'Wait' renamed to 'Wait_State' (VHDL reserved keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    d             : in  std_logic;
    done_counting : in  std_logic;
    ack           : in  std_logic;
    state         : in  std_logic_vector(9 downto 0);
    B3_next       : out std_logic;
    S_next        : out std_logic;
    S1_next       : out std_logic;
    Count_next    : out std_logic;
    Wait_next     : out std_logic;
    done          : out std_logic;
    counting      : out std_logic;
    shift_ena     : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  -- State bit positions
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

  -- Next-state logic
  B3_next <= state(B2);
  
  S_next <= (state(S) and not d) or
            (state(S1) and not d) or
            (state(S110) and not d) or
            (state(Wait_State) and ack);
  
  S1_next <= state(S) and d;
  
  Count_next <= state(B3) or (state(Count) and not done_counting);
  
  Wait_next <= (state(Count) and done_counting) or
               (state(Wait_State) and not ack);
  
  -- Output logic
  done <= state(Wait_State);
  
  counting <= state(Count);
  
  shift_ena <= state(B0) or state(B1) or state(B2) or state(B3);

end architecture rtl;