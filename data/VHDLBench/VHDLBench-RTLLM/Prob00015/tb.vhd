-- (1) Testbench with integrated stimulus (tb entity)
-- VUnit framework + stimulus generation + verification against expected values
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  -- ========== Constants ==========
  constant clk_period : time := 20 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '1';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal mul_a : std_logic_vector(7 downto 0) := (others => '0');
  signal mul_b : std_logic_vector(7 downto 0) := (others => '0');
  signal mul_en_in : std_logic := '0';
  signal mul_en_out : std_logic;
  signal mul_out : std_logic_vector(15 downto 0);
  
  -- Verification signals
  signal expected_product : unsigned(15 downto 0) := (others => '0');
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_mul_out     : integer;
    errortime_mul_out  : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_mul_out     => 0,
    errortime_mul_out  => 0 ps,
    clocks             => 0
  );
  
  signal test_count : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '1';
    wait for clk_period / 2;
    clk <= '0';
    wait for clk_period / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.multi_pipe_8bit
    port map (
      clk         => clk,
      rst_n       => rst_n,
      mul_a       => mul_a,
      mul_b       => mul_b,
      mul_en_in   => mul_en_in,
      mul_en_out  => mul_en_out,
      mul_out     => mul_out
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable rand_val : real;
    variable mul_a_val : integer;
    variable mul_b_val : integer;
  begin
    sim_done <= false;
    
    -- Initial reset
    rst_n <= '0';
    mul_a <= (others => '0');
    mul_b <= (others => '0');
    mul_en_in <= '0';
    
    -- Wait for 200 clock periods + 1ns
    wait for clk_period * 200 + 1 ns;
    
    rst_n <= '1';
    
    wait for clk_period * 10;
    
    -- First test case
    mul_a <= std_logic_vector(to_unsigned(35, 8));
    mul_b <= std_logic_vector(to_unsigned(20, 8));
    mul_en_in <= '1';
    
    -- 100 random test cases
    for i in 0 to 99 loop
      mul_en_in <= '0';
      wait for clk_period * 20;
      
      rst_n <= '1';
      wait for clk_period * 10;
      
      -- Generate random values using ieee.math_real.uniform
      uniform(seed1, seed2, rand_val);
      mul_a_val := integer(rand_val * 255.0);
      uniform(seed1, seed2, rand_val);
      mul_b_val := integer(rand_val * 255.0);
      
      mul_a <= std_logic_vector(to_unsigned(mul_a_val, 8));
      mul_b <= std_logic_vector(to_unsigned(mul_b_val, 8));
      mul_en_in <= '1';
      
      wait for clk_period * 1;
      
      -- Calculate expected product
      expected_product <= to_unsigned(mul_a_val, 8) * to_unsigned(mul_b_val, 8);
      
      wait for clk_period * 1;
      
      -- Wait for mul_en_out to go high
      while mul_en_out = '0' loop
        wait until rising_edge(clk);
      end loop;
      
      test_count <= test_count + 1;
    end loop;
    
    wait for clk_period * 10;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification ==========
  verify_process : process(clk)
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check output when mul_en_out is active
        if mul_en_out = '1' then
          if unsigned(mul_out) /= expected_product then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_mul_out <= stats1.errors_mul_out + 1;
            
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_mul_out = 1 then
              stats1.errortime_mul_out <= now;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- ========== VUnit Test Runner ==========
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  -- ========== Report Generation ==========
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_mul_out > 0 then
      write(l, string'("Hint: Output 'mul_out' has "));
      write(l, stats1.errors_mul_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_mul_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'mul_out' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.clocks);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.clocks);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_mul_out > 0 then
      info("Hint: Output 'mul_out' has " & integer'image(stats1.errors_mul_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_mul_out / 1 ps) & ".");
    else
      info("Hint: Output 'mul_out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(stats1.errors) & " /100 failures===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;