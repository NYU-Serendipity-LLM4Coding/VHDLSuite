-- VHDL Implementation of multi_16bit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_16bit is
  port (
    clk    : in  std_logic;
    rst_n  : in  std_logic;
    start  : in  std_logic;
    ain    : in  std_logic_vector(15 downto 0);
    bin    : in  std_logic_vector(15 downto 0);
    yout   : out std_logic_vector(31 downto 0);
    done   : out std_logic
  );
end entity multi_16bit;

architecture rtl of multi_16bit is
  -- Internal registers
  signal areg    : unsigned(15 downto 0) := (others => '0');
  signal breg    : unsigned(15 downto 0) := (others => '0');
  signal yout_r  : unsigned(31 downto 0) := (others => '0');
  signal done_r  : std_logic := '0';
  signal i       : unsigned(4 downto 0) := (others => '0');
  
begin

  -- ========== Data bit control ==========
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      i <= (others => '0');
    elsif rising_edge(clk) then
      if start = '1' and i < 17 then
        i <= i + 1;
      elsif start = '0' then
        i <= (others => '0');
      end if;
    end if;
  end process;
  
  -- ========== Multiplication completion flag generation ==========
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      done_r <= '0';
    elsif rising_edge(clk) then
      if i = 16 then
        done_r <= '1';
      elsif i = 17 then
        done_r <= '0';
      end if;
    end if;
  end process;
  
  done <= done_r;
  
  -- ========== Shift and accumulate operation ==========
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      areg <= (others => '0');
      breg <= (others => '0');
      yout_r <= (others => '0');
    elsif rising_edge(clk) then
      if start = '1' then
        if i = 0 then
          -- Store multiplicand and multiplier
          areg <= unsigned(ain);
          breg <= unsigned(bin);
        elsif i > 0 and i < 17 then
          -- Shift and accumulate
          if areg(to_integer(i) - 1) = '1' then
            yout_r <= yout_r + (resize(breg, 32) sll (to_integer(i) - 1));
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- ========== Output assignment ==========
  yout <= std_logic_vector(yout_r);

end architecture rtl;