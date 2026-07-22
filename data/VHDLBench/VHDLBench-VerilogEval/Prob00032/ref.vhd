-- (3) Reference implementation (RefModule)
-- Reference Module: Vector Splitter
-- Passes through 3-bit vector and splits it into individual bits
-- Matches Verilog: assign outv = vec; assign {o2, o1, o0} = vec;

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    vec  : in  std_logic_vector(2 downto 0);
    outv : out std_logic_vector(2 downto 0);
    o2   : out std_logic;
    o1   : out std_logic;
    o0   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign outv = vec;
  outv <= vec;
  
  -- Matches Verilog: assign {o2, o1, o0} = vec;
  -- In VHDL, we assign individual bits
  o2 <= vec(2);
  o1 <= vec(1);
  o0 <= vec(0);

end architecture rtl;