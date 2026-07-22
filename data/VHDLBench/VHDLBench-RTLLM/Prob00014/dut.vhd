-- (2) DUT implementation (multi_pipe_4bit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_pipe_4bit is
  generic (
    size : integer := 4
  );
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    mul_a   : in  std_logic_vector(size-1 downto 0);
    mul_b   : in  std_logic_vector(size-1 downto 0);
    mul_out : out std_logic_vector(size*2-1 downto 0)
  );
end entity multi_pipe_4bit;

architecture rtl of multi_pipe_4bit is
  constant N : integer := 2 * size;
  
  -- Pipeline registers
  signal sum_tmp1 : unsigned(N-1 downto 0);
  signal sum_tmp2 : unsigned(N-1 downto 0);
  
  -- Extended input signals
  signal mul_a_extend : unsigned(N-1 downto 0);
  signal mul_b_extend : unsigned(N-1 downto 0);
  
  -- Array type for partial products
  type mul_result_array_t is array (0 to size-1) of unsigned(N-1 downto 0);
  signal mul_result : mul_result_array_t;
  
begin

  -- Extension of input signals (add size zeros at MSB)
  mul_a_extend <= resize(unsigned(mul_a), N);
  mul_b_extend <= resize(unsigned(mul_b), N);
  
  -- Generate partial products
  gen_partial_products: for i in 0 to size-1 generate
    mul_result(i) <= shift_left(mul_a_extend, i) when mul_b(i) = '1' else (others => '0');
  end generate;
  
  -- First pipeline stage: sum pairs of partial products
  pipeline_stage1 : process(clk, rst_n)
  begin
    if rst_n = '0' then
      sum_tmp1 <= (others => '0');
      sum_tmp2 <= (others => '0');
    elsif rising_edge(clk) then
      sum_tmp1 <= mul_result(0) + mul_result(1);
      sum_tmp2 <= mul_result(2) + mul_result(3);
    end if;
  end process;
  
  -- Second pipeline stage: final product calculation
  pipeline_stage2 : process(clk, rst_n)
  begin
    if rst_n = '0' then
      mul_out <= (others => '0');
    elsif rising_edge(clk) then
      mul_out <= std_logic_vector(sum_tmp1 + sum_tmp2);
    end if;
  end process;
  
end architecture rtl;