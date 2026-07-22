library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator_3bit is
  port (
    A : in std_logic_vector(2 downto 0);
    B : in std_logic_vector(2 downto 0);
    A_greater : out std_logic;
    A_equal : out std_logic;
    A_less : out std_logic
  );
end entity comparator_3bit;

architecture rtl of comparator_3bit is
begin

  A_greater <= '1' when unsigned(A) > unsigned(B) else '0';
  A_equal   <= '1' when unsigned(A) = unsigned(B) else '0';
  A_less    <= '1' when unsigned(A) < unsigned(B) else '0';

end architecture rtl;