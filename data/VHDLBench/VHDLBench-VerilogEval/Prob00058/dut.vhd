-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement XOR gate three ways

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk             : in  std_logic;
    a               : in  std_logic;
    b               : in  std_logic;
    out_assign      : out std_logic;
    out_always_comb : out std_logic;
    out_always_ff   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Method 1: Concurrent assignment
  out_assign <= a xor b;
  
  -- Method 2: Combinational process
  process(a, b)
  begin
    out_always_comb <= a xor b;
  end process;
  
  -- Method 3: Clocked process
  process(clk)
  begin
    if rising_edge(clk) then
      out_always_ff <= a xor b;
    end if;
  end process;

end architecture rtl;