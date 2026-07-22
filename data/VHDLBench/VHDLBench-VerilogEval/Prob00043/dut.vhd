-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement pairwise comparison of 5 input bits

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    d          : in  std_logic;
    e          : in  std_logic;
    signal_out : out std_logic_vector(24 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal inverted_replicated : std_logic_vector(24 downto 0);
  signal normal_replicated   : std_logic_vector(24 downto 0);
begin
  
  inverted_replicated <= not (
    (4 downto 0 => a) &
    (4 downto 0 => b) &
    (4 downto 0 => c) &
    (4 downto 0 => d) &
    (4 downto 0 => e)
  );
  
  normal_replicated <= 
    (a & b & c & d & e) &
    (a & b & c & d & e) &
    (a & b & c & d & e) &
    (a & b & c & d & e) &
    (a & b & c & d & e);
  
  signal_out <= inverted_replicated xor normal_replicated;

end architecture rtl;