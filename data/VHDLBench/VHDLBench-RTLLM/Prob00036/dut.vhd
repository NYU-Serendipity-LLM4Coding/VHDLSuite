-- (2) DUT implementation (edge_detect)
library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    a     : in  std_logic;
    rise  : out std_logic;
    down  : out std_logic
  );
end entity edge_detect;

architecture rtl of edge_detect is
  signal a0 : std_logic;
begin

  -- Edge detection process
  edge_detect_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      rise <= '0';
      down <= '0';
    elsif rising_edge(clk) then
      if a = '1' and a0 = '0' then
        -- Rising edge detected
        rise <= '1';
        down <= '0';
      elsif a = '0' and a0 = '1' then
        -- Falling edge detected
        rise <= '0';
        down <= '1';
      else
        -- No edge
        rise <= '0';
        down <= '0';
      end if;
    end if;
  end process;
  
  -- Register previous value of 'a'
  register_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      a0 <= '0';
    elsif rising_edge(clk) then
      a0 <= a;
    end if;
  end process;

end architecture rtl;