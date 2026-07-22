-- (3) Reference implementation (RefModule)
-- Reference Module: 2-bit Equality Comparator
-- Output z = 1 when A[1:0] = B[1:0], otherwise z = 0
-- Matches Verilog: assign z = A[1:0]==B[1:0];

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    A : in  std_logic_vector(1 downto 0);
    B : in  std_logic_vector(1 downto 0);
    z : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign z = A[1:0]==B[1:0];
  z <= '1' when (A = B) else '0';

end architecture rtl;