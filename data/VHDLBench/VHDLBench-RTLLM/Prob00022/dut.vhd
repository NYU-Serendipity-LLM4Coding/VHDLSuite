-- (2) DUT implementation (ring_counter)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ring_counter is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    o     : out std_logic_vector(7 downto 0)
  );
end entity ring_counter;

architecture rtl of ring_counter is
  signal state : std_logic_vector(7 downto 0);
begin

  -- State register with rotation logic
  state_proc : process(clk, reset)
  begin
    if reset = '1' then
      state <= "00000001";  -- Initialize to LSB set
    elsif rising_edge(clk) then
      -- Rotate left: shift left and wrap MSB to LSB
      state <= state(6 downto 0) & state(7);
    end if;
  end process;
  
  -- Output assignment
  o <= state;
  
end architecture rtl;