-- (3) Reference implementation (RefModule)
-- Reference Module: State Machine Next-State Logic
-- Computes Y1 and Y3 for one-hot encoded state machine
-- Y1 = y[0] AND w (transition A->B when w=1)
-- Y3 = (y[1] OR y[2] OR y[4] OR y[5]) AND NOT w (transitions to D when w=0)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    y  : in  std_logic_vector(5 downto 0);
    w  : in  std_logic;
    Y1 : out std_logic;
    Y3 : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign Y1 = y[0] & w;
  Y1 <= y(0) and w;
  
  -- Matches Verilog: assign Y3 = (y[1]|y[2]|y[4]|y[5]) & ~w;
  Y3 <= (y(1) or y(2) or y(4) or y(5)) and (not w);

end architecture rtl;