-- (2) DUT implementation
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_divbyodd is
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    clk_div : out std_logic
  );
end entity freq_divbyodd;

architecture rtl of freq_divbyodd is
  constant NUM_DIV : integer := 5;
  
  signal cnt1 : unsigned(2 downto 0);
  signal cnt2 : unsigned(2 downto 0);
  signal clk_div1 : std_logic;
  signal clk_div2 : std_logic;
  
begin

  -- Counter 1 (positive edge)
  cnt1_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt1 <= (others => '0');
    elsif rising_edge(clk) then
      if cnt1 < NUM_DIV - 1 then
        cnt1 <= cnt1 + 1;
      else
        cnt1 <= (others => '0');
      end if;
    end if;
  end process;
  
  -- Clock divider 1 (positive edge)
  clk_div1_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      clk_div1 <= '1';
    elsif rising_edge(clk) then
      if cnt1 < NUM_DIV / 2 then
        clk_div1 <= '1';
      else
        clk_div1 <= '0';
      end if;
    end if;
  end process;
  
  -- Counter 2 (negative edge)
  cnt2_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt2 <= (others => '0');
    elsif falling_edge(clk) then
      if cnt2 < NUM_DIV - 1 then
        cnt2 <= cnt2 + 1;
      else
        cnt2 <= (others => '0');
      end if;
    end if;
  end process;
  
  -- Clock divider 2 (negative edge)
  clk_div2_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      clk_div2 <= '1';
    elsif falling_edge(clk) then
      if cnt2 < NUM_DIV / 2 then
        clk_div2 <= '1';
      else
        clk_div2 <= '0';
      end if;
    end if;
  end process;
  
  -- Output assignment
  clk_div <= clk_div1 or clk_div2;
  
end architecture rtl;