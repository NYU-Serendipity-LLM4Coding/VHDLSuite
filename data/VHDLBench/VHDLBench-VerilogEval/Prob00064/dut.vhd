-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement vector concatenation and split

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a : in  std_logic_vector(4 downto 0);
    b : in  std_logic_vector(4 downto 0);
    c : in  std_logic_vector(4 downto 0);
    d : in  std_logic_vector(4 downto 0);
    e : in  std_logic_vector(4 downto 0);
    f : in  std_logic_vector(4 downto 0);
    w : out std_logic_vector(7 downto 0);
    x : out std_logic_vector(7 downto 0);
    y : out std_logic_vector(7 downto 0);
    z : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal concat : std_logic_vector(31 downto 0);
begin
  
  concat <= a & b & c & d & e & f & "11";
  
  w <= concat(31 downto 24);
  x <= concat(23 downto 16);
  y <= concat(15 downto 8);
  z <= concat(7 downto 0);

end architecture rtl;