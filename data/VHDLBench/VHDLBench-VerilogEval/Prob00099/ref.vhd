-- (3) Reference implementation (RefModule)
-- Reference Module: One-Hot State Machine Next-State Logic
-- Computes Y2 and Y4 based on one-hot encoded state y[6:1]
-- State encoding: A=000001, B=000010, C=000100, D=001000, E=010000, F=100000
-- Y2 = y[1] & ~w  (next state is B when in A and w=0)
-- Y4 = (y[2] | y[3] | y[5] | y[6]) & w  (next state is D from B,C,E,F when w=1)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    y  : in  std_logic_vector(6 downto 1);
    w  : in  std_logic;
    Y2 : out std_logic;
    Y4 : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign Y2 = y[1] & ~w;
  Y2 <= y(1) and (not w);
  
  -- Matches Verilog: assign Y4 = (y[2] | y[3] | y[5] | y[6]) & w;
  Y4 <= (y(2) or y(3) or y(5) or y(6)) and w;

end architecture rtl;