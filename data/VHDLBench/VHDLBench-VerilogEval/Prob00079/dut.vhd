-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: One-hot state machine combinational logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic;
    state      : in  std_logic_vector(3 downto 0);
    next_state : out std_logic_vector(3 downto 0);
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  -- State bit indices
  constant A : integer := 0;
  constant B : integer := 1;
  constant C : integer := 2;
  constant D : integer := 3;
begin
  
  -- State transition logic (derived from state table)
  next_state(A) <= (state(A) or state(C)) and (not signal_in);
  next_state(B) <= (state(A) or state(B) or state(D)) and signal_in;
  next_state(C) <= (state(B) or state(D)) and (not signal_in);
  next_state(D) <= state(C) and signal_in;
  
  -- Output logic (Moore machine - output depends only on state)
  signal_out <= state(D);

end architecture rtl;