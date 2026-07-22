-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_pipe_8bit is
  generic (
    size : integer := 8
  );
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    mul_a       : in  std_logic_vector(size-1 downto 0);
    mul_b       : in  std_logic_vector(size-1 downto 0);
    mul_en_in   : in  std_logic;
    mul_en_out  : out std_logic;
    mul_out     : out std_logic_vector(size*2-1 downto 0)
  );
end entity multi_pipe_8bit;

architecture rtl of multi_pipe_8bit is
  
  -- Enable pipeline register
  signal mul_en_out_reg : std_logic_vector(2 downto 0);
  
  -- Input registers
  signal mul_a_reg : std_logic_vector(7 downto 0);
  signal mul_b_reg : std_logic_vector(7 downto 0);
  
  -- Partial products
  type temp_array_t is array (0 to size-1) of unsigned(15 downto 0);
  signal temp : temp_array_t;
  
  -- Partial sums
  type sum_array_t is array (0 to 3) of unsigned(15 downto 0);
  signal sum : sum_array_t;
  
  -- Final product register
  signal mul_out_reg : unsigned(15 downto 0);
  
begin

  -- ========== Enable Pipeline ==========
  enable_pipeline : process(clk, rst_n)
  begin
    if rst_n = '0' then
      mul_en_out_reg <= (others => '0');
      mul_en_out <= '0';
    elsif rising_edge(clk) then
      mul_en_out_reg <= mul_en_out_reg(1 downto 0) & mul_en_in;
      mul_en_out <= mul_en_out_reg(2);
    end if;
  end process;
  
  -- ========== Input Registers ==========
  input_regs : process(clk, rst_n)
  begin
    if rst_n = '0' then
      mul_a_reg <= (others => '0');
      mul_b_reg <= (others => '0');
    elsif rising_edge(clk) then
      if mul_en_in = '1' then
        mul_a_reg <= mul_a;
        mul_b_reg <= mul_b;
      else
        mul_a_reg <= (others => '0');
        mul_b_reg <= (others => '0');
      end if;
    end if;
  end process;
  
  -- ========== Partial Product Generation ==========
  temp(0) <= resize(unsigned(mul_a_reg), 16)           when mul_b_reg(0) = '1' else (others => '0');
  temp(1) <= resize(unsigned(mul_a_reg) & '0', 16)     when mul_b_reg(1) = '1' else (others => '0');
  temp(2) <= resize(unsigned(mul_a_reg) & "00", 16)    when mul_b_reg(2) = '1' else (others => '0');
  temp(3) <= resize(unsigned(mul_a_reg) & "000", 16)   when mul_b_reg(3) = '1' else (others => '0');
  temp(4) <= resize(unsigned(mul_a_reg) & "0000", 16)  when mul_b_reg(4) = '1' else (others => '0');
  temp(5) <= resize(unsigned(mul_a_reg) & "00000", 16) when mul_b_reg(5) = '1' else (others => '0');
  temp(6) <= resize(unsigned(mul_a_reg) & "000000", 16) when mul_b_reg(6) = '1' else (others => '0');
  temp(7) <= resize(unsigned(mul_a_reg) & "0000000", 16) when mul_b_reg(7) = '1' else (others => '0');
  
  -- ========== Partial Sum Calculation ==========
  partial_sum : process(clk, rst_n)
  begin
    if rst_n = '0' then
      sum(0) <= (others => '0');
      sum(1) <= (others => '0');
      sum(2) <= (others => '0');
      sum(3) <= (others => '0');
    elsif rising_edge(clk) then
      sum(0) <= temp(0) + temp(1);
      sum(1) <= temp(2) + temp(3);
      sum(2) <= temp(4) + temp(5);
      sum(3) <= temp(6) + temp(7);
    end if;
  end process;
  
  -- ========== Final Product Calculation ==========
  final_product : process(clk, rst_n)
  begin
    if rst_n = '0' then
      mul_out_reg <= (others => '0');
    elsif rising_edge(clk) then
      mul_out_reg <= sum(0) + sum(1) + sum(2) + sum(3);
    end if;
  end process;
  
  -- ========== Output Assignment ==========
  output_assign : process(clk, rst_n)
  begin
    if rst_n = '0' then
      mul_out <= (others => '0');
    elsif rising_edge(clk) then
      if mul_en_out_reg(2) = '1' then
        mul_out <= std_logic_vector(mul_out_reg);
      else
        mul_out <= (others => '0');
      end if;
    end if;
  end process;
  
end architecture rtl;