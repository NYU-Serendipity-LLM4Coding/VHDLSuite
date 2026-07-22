-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 12-hour BCD clock with AM/PM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    ena   : in  std_logic;
    pm    : out std_logic;
    hh    : out std_logic_vector(7 downto 0);
    mm    : out std_logic_vector(7 downto 0);
    ss    : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal pm_reg : std_logic := '0';
  signal hh_reg : std_logic_vector(7 downto 0) := x"12";
  signal mm_reg : std_logic_vector(7 downto 0) := x"00";
  signal ss_reg : std_logic_vector(7 downto 0) := x"00";
  
  signal enable : std_logic_vector(6 downto 0);
  
begin
  
  pm <= pm_reg;
  hh <= hh_reg;
  mm <= mm_reg;
  ss <= ss_reg;
  
  -- Enable cascade logic
  enable(0) <= '1';
  enable(1) <= '1' when (ss_reg(3 downto 0) = x"9") else '0';
  enable(2) <= '1' when (ss_reg(7 downto 0) = x"59") else '0';
  enable(3) <= '1' when (mm_reg(3 downto 0) = x"9" and ss_reg(7 downto 0) = x"59") else '0';
  enable(4) <= '1' when (mm_reg(7 downto 0) = x"59" and ss_reg(7 downto 0) = x"59") else '0';
  enable(5) <= '1' when (hh_reg(3 downto 0) = x"9" and mm_reg(7 downto 0) = x"59" and ss_reg(7 downto 0) = x"59") else '0';
  enable(6) <= '1' when (hh_reg(7 downto 0) = x"11" and mm_reg(7 downto 0) = x"59" and ss_reg(7 downto 0) = x"59") else '0';
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pm_reg <= '0';
        hh_reg <= x"12";
        mm_reg <= x"00";
        ss_reg <= x"00";
      elsif ena = '1' then
        -- Seconds ones digit
        if enable(0) = '1' and ss_reg(3 downto 0) = x"9" then
          ss_reg(3 downto 0) <= x"0";
        elsif enable(0) = '1' then
          ss_reg(3 downto 0) <= std_logic_vector(unsigned(ss_reg(3 downto 0)) + 1);
        end if;
        
        -- Seconds tens digit
        if enable(1) = '1' and ss_reg(7 downto 4) = x"5" then
          ss_reg(7 downto 4) <= x"0";
        elsif enable(1) = '1' then
          ss_reg(7 downto 4) <= std_logic_vector(unsigned(ss_reg(7 downto 4)) + 1);
        end if;
        
        -- Minutes ones digit
        if enable(2) = '1' and mm_reg(3 downto 0) = x"9" then
          mm_reg(3 downto 0) <= x"0";
        elsif enable(2) = '1' then
          mm_reg(3 downto 0) <= std_logic_vector(unsigned(mm_reg(3 downto 0)) + 1);
        end if;
        
        -- Minutes tens digit
        if enable(3) = '1' and mm_reg(7 downto 4) = x"5" then
          mm_reg(7 downto 4) <= x"0";
        elsif enable(3) = '1' then
          mm_reg(7 downto 4) <= std_logic_vector(unsigned(mm_reg(7 downto 4)) + 1);
        end if;
        
        -- Hours ones digit
        if enable(4) = '1' and hh_reg(3 downto 0) = x"9" then
          hh_reg(3 downto 0) <= x"0";
        elsif enable(4) = '1' then
          hh_reg(3 downto 0) <= std_logic_vector(unsigned(hh_reg(3 downto 0)) + 1);
        end if;
        
        -- Hours special handling (12-hour wrap)
        if enable(4) = '1' and hh_reg(7 downto 0) = x"12" then
          hh_reg(7 downto 0) <= x"01";
        elsif enable(5) = '1' then
          hh_reg(7 downto 4) <= std_logic_vector(unsigned(hh_reg(7 downto 4)) + 1);
        end if;
        
        -- PM toggle (at 11:59:59 -> 12:00:00)
        if enable(6) = '1' then
          pm_reg <= not pm_reg;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;