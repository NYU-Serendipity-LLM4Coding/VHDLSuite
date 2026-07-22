-- (2) DUT implementation (freq_div)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_div is
  port (
    CLK_in  : in  std_logic;
    RST     : in  std_logic;
    CLK_50  : out std_logic;
    CLK_10  : out std_logic;
    CLK_1   : out std_logic
  );
end entity freq_div;

architecture rtl of freq_div is
  signal clk_50_reg  : std_logic := '0';
  signal clk_10_reg  : std_logic := '0';
  signal clk_1_reg   : std_logic := '0';
  signal cnt_10      : unsigned(3 downto 0) := (others => '0');
  signal cnt_100     : unsigned(6 downto 0) := (others => '0');
  
begin

  -- CLK_50 generation (divide by 2)
  clk_50_proc : process(CLK_in, RST)
  begin
    if RST = '1' then
      clk_50_reg <= '0';
    elsif rising_edge(CLK_in) then
      clk_50_reg <= not clk_50_reg;
    end if;
  end process;
  
  CLK_50 <= clk_50_reg;
  
  -- CLK_10 generation (divide by 10)
  clk_10_proc : process(CLK_in, RST)
  begin
    if RST = '1' then
      clk_10_reg <= '0';
      cnt_10 <= (others => '0');
    elsif rising_edge(CLK_in) then
      if cnt_10 = 4 then
        clk_10_reg <= not clk_10_reg;
        cnt_10 <= (others => '0');
      else
        cnt_10 <= cnt_10 + 1;
      end if;
    end if;
  end process;
  
  CLK_10 <= clk_10_reg;
  
  -- CLK_1 generation (divide by 100)
  clk_1_proc : process(CLK_in, RST)
  begin
    if RST = '1' then
      clk_1_reg <= '0';
      cnt_100 <= (others => '0');
    elsif rising_edge(CLK_in) then
      if cnt_100 = 49 then
        clk_1_reg <= not clk_1_reg;
        cnt_100 <= (others => '0');
      else
        cnt_100 <= cnt_100 + 1;
      end if;
    end if;
  end process;
  
  CLK_1 <= clk_1_reg;
  
end architecture rtl;