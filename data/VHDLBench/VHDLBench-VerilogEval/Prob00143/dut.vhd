-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement one-hot state machine next-state and output logic

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in  : in  std_logic;
    state      : in  std_logic_vector(9 downto 0);
    next_state : out std_logic_vector(9 downto 0);
    out1       : out std_logic;
    out2       : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal or_state_4_0 : std_logic;
begin
  
  -- Output logic
  out1 <= state(8) or state(9);
  out2 <= state(7) or state(9);
  
  -- Reduction OR for state[4:0]
  or_state_4_0 <= state(0) or state(1) or state(2) or state(3) or state(4);
  
  -- Next state logic
  next_state(0) <= (not signal_in) and 
                   (or_state_4_0 or state(7) or state(8) or state(9));
  next_state(1) <= signal_in and (state(0) or state(8) or state(9));
  next_state(2) <= signal_in and state(1);
  next_state(3) <= signal_in and state(2);
  next_state(4) <= signal_in and state(3);
  next_state(5) <= signal_in and state(4);
  next_state(6) <= signal_in and state(5);
  next_state(7) <= signal_in and (state(6) or state(7));
  next_state(8) <= (not signal_in) and state(5);
  next_state(9) <= (not signal_in) and state(6);

end architecture rtl;