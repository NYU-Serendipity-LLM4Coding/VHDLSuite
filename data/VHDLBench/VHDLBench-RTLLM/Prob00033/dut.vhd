library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_divbyfrac is
  port (
    rst_n   : in  std_logic;
    clk     : in  std_logic;
    clk_div : out std_logic
  );
end entity freq_divbyfrac;

architecture rtl of freq_divbyfrac is
  constant MUL2_DIV_CLK : integer := 7;
  
  signal cnt : unsigned(3 downto 0);
  signal clk_ave_r : std_logic;
  signal clk_adjust_r : std_logic;
  
begin

  -- Counter process (posedge clk)
  -- From: always @(posedge clk or negedge rst_n)
  counter_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt <= (others => '0');
    elsif rising_edge(clk) then
      if cnt = MUL2_DIV_CLK - 1 then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  
  -- Average clock generation (posedge clk)
  -- From: always @(posedge clk or negedge rst_n)
  clk_ave_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      clk_ave_r <= '0';
    elsif rising_edge(clk) then
      -- First cycle: 4 source clk cycle
      if cnt = 0 then
        clk_ave_r <= '1';
      -- 2nd cycle: 3 source clk cycle
      elsif cnt = (MUL2_DIV_CLK / 2) + 1 then
        clk_ave_r <= '1';
      else
        clk_ave_r <= '0';
      end if;
    end if;
  end process;
  
  -- Adjust clock generation (negedge clk)
  -- From: always @(negedge clk or negedge rst_n)
  clk_adjust_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      clk_adjust_r <= '0';
    elsif falling_edge(clk) then
      if cnt = 1 then
        clk_adjust_r <= '1';
      elsif cnt = (MUL2_DIV_CLK / 2) + 1 then
        clk_adjust_r <= '1';
      else
        clk_adjust_r <= '0';
      end if;
    end if;
  end process;
  
  -- Output assignment
  -- From: assign clk_div = clk_adjust_r | clk_ave_r;
  clk_div <= clk_adjust_r or clk_ave_r;
  
end architecture rtl;