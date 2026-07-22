library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accu is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    data_in   : in  std_logic_vector(7 downto 0);
    valid_in  : in  std_logic;
    valid_out : out std_logic;
    data_out  : out std_logic_vector(9 downto 0)
  );
end entity accu;

architecture rtl of accu is
  signal count : unsigned(1 downto 0);
  signal data_out_reg : unsigned(9 downto 0);
  signal add_cnt : std_logic;
  signal end_cnt : std_logic;
  
begin

  -- Control signals
  add_cnt <= valid_in;
  end_cnt <= '1' when (add_cnt = '1' and count = "11") else '0';
  
  -- Counter process
  count_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      count <= (others => '0');
    elsif rising_edge(clk) then
      if end_cnt = '1' then
        count <= (others => '0');
      elsif add_cnt = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;
  
  -- Accumulator process
  accumulator_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      data_out_reg <= (others => '0');
    elsif rising_edge(clk) then
      if add_cnt = '1' then
        if count = "00" then
          data_out_reg <= resize(unsigned(data_in), 10);
        else
          data_out_reg <= data_out_reg + resize(unsigned(data_in), 10);
        end if;
      end if;
    end if;
  end process;
  
  -- Output assignment
  data_out <= std_logic_vector(data_out_reg);
  
  -- Valid output process
  valid_out_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      valid_out <= '0';
    elsif rising_edge(clk) then
      if end_cnt = '1' then
        valid_out <= '1';
      else
        valid_out <= '0';
      end if;
    end if;
  end process;
  
end architecture rtl;