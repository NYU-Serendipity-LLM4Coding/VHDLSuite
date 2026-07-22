-- (2) DUT implementation (serial2parallel)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serial2parallel is
  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    din_serial    : in  std_logic;
    din_valid     : in  std_logic;
    dout_parallel : out std_logic_vector(7 downto 0);
    dout_valid    : out std_logic
  );
end entity serial2parallel;

architecture rtl of serial2parallel is
  signal din_tmp : std_logic_vector(7 downto 0);
  signal cnt : unsigned(3 downto 0);
  
begin

  -- Counter process
  counter_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt <= (others => '0');
    elsif rising_edge(clk) then
      if din_valid = '1' then
        if cnt = 8 then
          cnt <= (others => '0');
        else
          cnt <= cnt + 1;
        end if;
      else
        cnt <= (others => '0');
      end if;
    end if;
  end process;
  
  -- Shift register process
  shift_reg_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      din_tmp <= (others => '0');
    elsif rising_edge(clk) then
      if din_valid = '1' and cnt <= 7 then
        din_tmp <= din_tmp(6 downto 0) & din_serial;
      end if;
    end if;
  end process;
  
  -- Output process
  output_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      dout_valid <= '0';
      dout_parallel <= (others => '0');
    elsif rising_edge(clk) then
      if cnt = 8 then
        dout_valid <= '1';
        dout_parallel <= din_tmp;
      else
        dout_valid <= '0';
      end if;
    end if;
  end process;
  
end architecture rtl;