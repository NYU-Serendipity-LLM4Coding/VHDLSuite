-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Sequential circuit with full adder logic

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    a     : in  std_logic;
    b     : in  std_logic;
    q     : out std_logic;
    state : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal c : std_logic := '0';
begin
  
  process(clk)
  begin
    if rising_edge(clk) then
      c <= (a and b) or (a and c) or (b and c);
    end if;
  end process;
  
  q <= a xor b xor c;
  state <= c;

end architecture rtl;