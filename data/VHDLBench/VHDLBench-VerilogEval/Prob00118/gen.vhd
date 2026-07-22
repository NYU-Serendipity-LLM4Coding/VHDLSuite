-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Branch History Register Test
-- Generates test patterns for branch prediction and misprediction handling
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk                  : in  std_logic;
    areset               : out std_logic;
    predict_valid        : out std_logic;
    predict_taken        : out std_logic;
    train_mispredicted   : out std_logic;
    train_taken          : out std_logic;
    train_history        : out std_logic_vector(31 downto 0);
    tb_match             : in  boolean;
    wavedrom_title       : out string(1 to 512);
    wavedrom_enable      : out std_logic;
    wavedrom_hide_after_time : out integer;
    sim_done             : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset_internal : std_logic := '1';
  signal predict_taken_r : std_logic := '0';
  signal train_taken_r : std_logic := '0';
  signal train_history_r : std_logic_vector(31 downto 0) := (others => '0');
begin

  -- Conditional assignments (matches Verilog ternary operators)
  areset <= reset_internal;
  
  stimulus_process : process
    variable seed1 : positive := 12345;
    variable seed2 : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random 32-bit vector generator
    procedure random_vector(signal sig : out std_logic_vector(31 downto 0)) is
      variable temp : unsigned(31 downto 0);
    begin
      for i in 0 to 31 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      sig <= std_logic_vector(temp);
    end procedure;
    
    -- Random range generator (for urandom_range)
    function random_range(min_val, max_val : integer) return integer is
      variable rand : real;
      variable result : integer;
    begin
      uniform(seed1, seed2, rand);
      result := min_val + integer(floor(rand * real(max_val - min_val + 1)));
      return result;
    end function;
    
    -- Reset test task (simplified - doesn't check async/sync)
    procedure reset_test(async : boolean := false) is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset_internal <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      reset_internal <= '1';
      
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset_internal <= '0';
    end procedure;
    
  begin
    -- Initialize
    sim_done <= false;
    wavedrom_enable <= '0';
    wavedrom_hide_after_time <= 0;
    
    -- Initial setup
    wait until rising_edge(clk);
    reset_internal <= '1';
    wait until rising_edge(clk);
    reset_internal <= '0';
    
    predict_taken_r <= '1';
    predict_valid <= '1';
    train_mispredicted <= '0';
    train_history_r <= x"00000005";
    train_taken_r <= '1';
    
    -- Asynchronous reset test
    wavedrom_enable <= '1';
    reset_test(true);
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    reset_internal <= '1';
    predict_valid <= '0';
    
    -- Predictions: Shift in
    wavedrom_enable <= '1';
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
      random_bit(predict_valid);
      random_bit(predict_taken_r);
    end loop;
    
    reset_internal <= '0';
    predict_valid <= '1';
    
    for i in 1 to 6 loop
      wait until rising_edge(clk);
      random_bit(predict_taken_r);
    end loop;
    
    predict_valid <= '0';
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
      random_bit(predict_taken_r);
    end loop;
    
    predict_valid <= '1';
    train_mispredicted <= '1';
    wait until rising_edge(clk);
    train_mispredicted <= '0';
    
    for i in 1 to 6 loop
      wait until rising_edge(clk);
      random_bit(predict_taken_r);
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random testing: repeat(2000) @(posedge clk, negedge clk)
    for i in 1 to 2000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      random_bit(predict_valid);
      random_bit(predict_taken_r);
      random_bit(train_taken_r);
      random_vector(train_history_r);
      
      -- train_mispredicted <= !($urandom_range(0,31))
      -- This means: 1 if random(0,31) == 0, else 0
      -- Probability = 1/32
      if random_range(0, 31) = 0 then
        train_mispredicted <= '1';
      else
        train_mispredicted <= '0';
      end if;
    end loop;
    
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;
  
  -- Conditional signal assignments (matches Verilog ternary)
  predict_taken <= predict_taken_r when predict_valid = '1' else 'X';
  train_taken <= train_taken_r when train_mispredicted = '1' else 'X';
  train_history <= train_history_r when train_mispredicted = '1' else (others => 'X');

end architecture behavioral;