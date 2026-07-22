-- (2) DUT implementation (width_8to16)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity width_8to16 is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    valid_in  : in  std_logic;
    data_in   : in  std_logic_vector(7 downto 0);
    valid_out : out std_logic;
    data_out  : out std_logic_vector(15 downto 0)
  );
end entity width_8to16;

architecture rtl of width_8to16 is
  signal data_lock : std_logic_vector(7 downto 0);
  signal flag : std_logic;
  
begin

  -- Input data buffer in data_lock
  data_lock_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      data_lock <= (others => '0');
    elsif rising_edge(clk) then
      if valid_in = '1' and flag = '0' then
        data_lock <= data_in;
      end if;
    end if;
  end process;
  
  -- Generate flag (toggles on each valid input)
  flag_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      flag <= '0';
    elsif rising_edge(clk) then
      if valid_in = '1' then
        flag <= not flag;
      end if;
    end if;
  end process;
  
  -- Generate valid_out
  valid_out_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      valid_out <= '0';
    elsif rising_edge(clk) then
      if valid_in = '1' and flag = '1' then
        valid_out <= '1';
      else
        valid_out <= '0';
      end if;
    end if;
  end process;
  
  -- Data stitching (concatenation)
  data_out_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      data_out <= (others => '0');
    elsif rising_edge(clk) then
      if valid_in = '1' and flag = '1' then
        data_out <= data_lock & data_in;
      end if;
    end if;
  end process;
  
end architecture rtl;