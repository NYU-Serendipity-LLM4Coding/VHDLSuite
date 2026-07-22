-- (2) DUT implementation (clkgenerator)
library ieee;
use ieee.std_logic_1164.all;

entity clkgenerator is
  port (
    clk : out std_logic
  );
end entity clkgenerator;

architecture rtl of clkgenerator is
  constant PERIOD : time := 10 ns;  -- Clock period parameter
  signal clk_internal : std_logic := '0';  -- Internal clock signal
begin

  -- Clock generation process
  -- From: always begin #(PERIOD/2) clk = ~clk; end
  clk_gen_process : process
  begin
    clk_internal <= '0';  -- Initial value from: initial begin clk = 0; end
    
    loop
      wait for PERIOD / 2;
      clk_internal <= not clk_internal;  -- Toggle clock
    end loop;
  end process;
  
  -- Output assignment
  clk <= clk_internal;

end architecture rtl;