-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for GShare Branch Predictor Test
-- Generates prediction and training requests with random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  generic (
    N : integer := 7
  );
  port (
    clk                  : in  std_logic;
    areset               : out std_logic;
    predict_valid        : out std_logic;
    predict_pc           : out std_logic_vector(N-1 downto 0);
    train_valid          : out std_logic;
    train_taken          : out std_logic;
    train_mispredicted   : out std_logic;
    train_history        : out std_logic_vector(N-1 downto 0);
    train_pc             : out std_logic_vector(N-1 downto 0);
    tb_match             : in  boolean;
    wavedrom_title       : out string(1 to 512);
    wavedrom_enable      : out std_logic;
    wavedrom_hide_after_time : out integer;
    sim_done             : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  signal reset_r              : std_logic := '1';
  signal predict_valid_r      : std_logic := '0';
  signal predict_pc_r         : std_logic_vector(N-1 downto 0) := (others => '0');
  signal train_valid_r        : std_logic := '0';
  signal train_taken_r        : std_logic := '0';
  signal train_mispredicted_r : std_logic := '0';
  signal train_history_r      : std_logic_vector(N-1 downto 0) := (others => '0');
  signal train_pc_r           : std_logic_vector(N-1 downto 0) := (others => '0');
  
begin

  areset <= reset_r;
  
  -- Drive outputs with X when invalid (matches Verilog ternary operators)
  predict_pc         <= predict_pc_r when predict_valid_r = '1' else (others => 'X');
  train_taken        <= train_taken_r when train_valid_r = '1' else 'X';
  train_mispredicted <= train_mispredicted_r when train_valid_r = '1' else 'X';
  train_history      <= train_history_r when train_valid_r = '1' else (others => 'X');
  train_pc           <= train_pc_r when train_valid_r = '1' else (others => 'X');
  
  predict_valid <= predict_valid_r;
  train_valid   <= train_valid_r;

  stimulus_process : process
    variable seed1    : positive := 123456;
    variable seed2    : positive := 789012;
    variable rand_val : real;
    variable rand_int : integer;
    variable rand_vec : std_logic_vector(31 downto 0);
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random vector generator
    procedure random_vector(signal vec : out std_logic_vector) is
      variable temp : std_logic_vector(vec'range);
    begin
      for i in vec'range loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      vec <= temp;
    end procedure;
    
    -- Random range generator (0 to max)
    procedure urandom_range(max : integer; variable result : out integer) is
    begin
      uniform(seed1, seed2, rand_val);
      result := integer(floor(rand_val * real(max + 1)));
      if result > max then
        result := max;
      end if;
    end procedure;
    
  begin
    -- Initialize
    sim_done <= false;
    wavedrom_enable <= '0';
    wavedrom_hide_after_time <= 0;
    
    -- Initial sequence
    wait until rising_edge(clk);
    reset_r <= '1';
    
    wait until rising_edge(clk);
    reset_r <= '0';
    predict_valid_r <= '1';
    train_mispredicted_r <= '1';
    train_history_r <= "1111111";  -- 7'h7f
    train_pc_r <= "0000100";       -- 7'h4
    train_taken_r <= '1';
    train_valid_r <= '1';
    predict_pc_r <= "0000100";     -- 4
    
    -- Wavedrom: Asynchronous reset test
    wavedrom_enable <= '1';
    
    -- reset_test(1) - asynchronous reset test
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset_r <= '0';
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    wait until falling_edge(clk);
    reset_r <= '1';
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset_r <= '0';
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    reset_r <= '1';
    predict_valid_r <= '0';
    
    -- Wavedrom: Training entries
    wavedrom_enable <= '1';
    predict_pc_r <= "0001010";  -- 7'ha
    predict_valid_r <= '1';
    train_history_r <= "0000000";  -- 7'h0
    train_pc_r <= "0001010";       -- 7'ha
    train_taken_r <= '1';
    train_valid_r <= '0';
    train_mispredicted_r <= '0';
    
    wait until falling_edge(clk);
    reset_r <= '0';
    
    wait until rising_edge(clk);
    train_valid_r <= '1';
    
    wait until rising_edge(clk);
    train_history_r <= "0000010";  -- 7'h2
    
    wait until rising_edge(clk);
    train_valid_r <= '0';
    
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    train_history_r <= "0000000";  -- 7'h0
    train_taken_r <= '0';
    train_valid_r <= '1';
    
    wait until rising_edge(clk);
    train_valid_r <= '0';
    
    for i in 1 to 8 loop
      wait until rising_edge(clk);
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    
    -- Wavedrom: History register recovery on misprediction
    wavedrom_enable <= '1';
    reset_r <= '1';
    predict_pc_r <= "0001010";  -- 7'ha
    predict_valid_r <= '1';
    train_history_r <= "0000000";  -- 7'h0
    train_pc_r <= "0001010";       -- 7'ha
    train_taken_r <= '1';
    train_valid_r <= '0';
    train_mispredicted_r <= '1';
    
    wait until falling_edge(clk);
    reset_r <= '0';
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    train_valid_r <= '1';
    
    wait until rising_edge(clk);
    train_valid_r <= '0';
    
    wait until rising_edge(clk);
    train_valid_r <= '1';
    train_history_r <= "0010000";  -- 7'h10
    train_taken_r <= '0';
    
    wait until rising_edge(clk);
    train_valid_r <= '0';
    
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    train_history_r <= "0000000";  -- 7'h0
    train_taken_r <= '0';
    train_valid_r <= '1';
    
    wait until rising_edge(clk);
    train_valid_r <= '0';
    
    wait until rising_edge(clk);
    train_valid_r <= '1';
    train_history_r <= "0100000";  -- 7'h20
    
    wait until rising_edge(clk);
    train_valid_r <= '0';
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(1000) @(posedge clk, negedge clk)
    for i in 1 to 1000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate random values
      random_bit(predict_valid_r);
      random_vector(predict_pc_r);
      random_vector(train_pc_r);
      random_bit(train_taken_r);
      random_bit(train_valid_r);
      random_vector(train_history_r);
      
      -- train_mispredicted_r <= !($urandom_range(0,31))
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      train_mispredicted_r <= '0' when rand_int /= 0 else '1';
    end loop;
    
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;