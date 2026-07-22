-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: XOR Flip-Flop with feedback

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal out_reg : std_logic := '0';
begin
  
  signal_out <= out_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      out_reg <= signal_in xor out_reg;
    end if;
  end process;

end architecture rtl;