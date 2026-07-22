-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Lemmings State Machine Test
-- Generates reset sequences and random test vectors
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    areset          : out std_logic;
    bump_left       : out std_logic;
    bump_right      : out std_logic;
    ground          : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic;
begin

  areset <= reset;

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random with bias (matches Verilog: |($random & 7) for ground)
    procedure random_ground(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      sig <= '1' when rand_int /= 0 else '0';
    end procedure;
    
    -- Random with bias (matches Verilog: !($random & 31) for reset)
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '0' when rand_int /= 0 else '1';
    end procedure;
    
    -- Reset test task (simplified - actual verification in tb)
    procedure reset_test is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      reset <= '1';
      
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
    end procedure;
    
    -- Wavedrom procedures (simplified)
    procedure wavedrom_start is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    bump_left <= '0';
    bump_right <= '0';
    ground <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial reset test (matches Verilog: reset_test(1))
    reset_test;
    
    bump_right <= '0';
    bump_left <= '0';
    
    -- Wavedrom section: "Falling"
    wavedrom_start;
    
    -- repeat(3) @(posedge clk)
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- {bump_right, bump_left, ground} <= 0
    bump_right <= '0';
    bump_left <= '0';
    ground <= '0';
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- {bump_right, bump_left, ground} <= 3 (binary: 011)
    bump_right <= '0';
    bump_left <= '1';
    ground <= '1';
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- {bump_right, bump_left, ground} <= 0
    bump_right <= '0';
    bump_left <= '0';
    ground <= '0';
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- {bump_right, bump_left, ground} <= 1 (binary: 001)
    bump_right <= '0';
    bump_left <= '0';
    ground <= '1';
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    -- Reset for random test
    reset <= '1';
    wait until rising_edge(clk);
    
    -- Random test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- {bump_right, bump_left} <= $random & $random (random bits)
      random_bit(bump_right);
      random_bit(bump_left);
      
      -- ground <= |($random & 7) (mostly 1, occasionally 0)
      random_ground(ground);
      
      -- reset <= !($random & 31) (mostly 0, occasionally 1)
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;