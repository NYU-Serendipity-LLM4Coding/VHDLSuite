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
  constant CLK_PERIOD : time := 10 ns;
  constant size : integer := 4;
  constant PIPELINE_DELAY : integer := 2;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal mul_a : std_logic_vector(3 downto 0) := (others => '0');
  signal mul_b : std_logic_vector(3 downto 0) := (others => '0');
  signal mul_out : std_logic_vector(7 downto 0);
  
  -- Expected value tracking with pipeline
  type expected_queue_t is array (0 to 109) of unsigned(7 downto 0);
  signal expected_queue : expected_queue_t := (others => (others => '0'));
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_mul_out     : integer;
    errortime_mul_out  : time;
    clocks             : integer;
    checks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_mul_out     => 0,
    errortime_mul_out  => 0 ps,
    clocks             => 0,
    checks             => 0
  );
  
  signal fail_count : integer := 0;
  signal total_tests : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.multi_pipe_4bit
    generic map (
      size => 4
    )
    port map (
      clk     => clk,
      rst_n   => rst_n,
      mul_a   => mul_a,
      mul_b   => mul_b,
      mul_out => mul_out
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1 : positive := 843253;
    variable seed2 : positive := 453816;
    variable rand_val : real;
    variable rand_int_a : integer;
    variable rand_int_b : integer;
    variable expected : unsigned(7 downto 0);
  begin
    sim_done <= false;
    
    -- Initialize inputs
    mul_a <= (others => '0');
    mul_b <= (others => '0');
    rst_n <= '0';
    
    -- Wait for reset
    wait for CLK_PERIOD * 1;
    
    -- Apply reset
    wait until rising_edge(clk);
    rst_n <= '1';
    
    -- Perform 100 test cases
    for i in 0 to NUM_TESTS-1 loop
      -- Generate random mul_a (0 to 15)
      uniform(seed1, seed2, rand_val);
      rand_int_a := integer(floor(rand_val * 16.0)) mod 16;
      
      -- Generate random mul_b (0 to 15)
      uniform(seed1, seed2, rand_val);
      rand_int_b := integer(floor(rand_val * 16.0)) mod 16;
      
      -- Calculate expected result
      expected := to_unsigned(rand_int_a * rand_int_b, 8);
      
      -- Store expected value in queue (will be checked after pipeline delay)
      expected_queue(i) <= expected;
      
      -- Apply inputs
      mul_a <= std_logic_vector(to_unsigned(rand_int_a, 4));
      mul_b <= std_logic_vector(to_unsigned(rand_int_b, 4));
      
      -- Wait for next clock edge
      wait until rising_edge(clk);
    end loop;
    
    total_tests <= NUM_TESTS;
    
    -- Wait for pipeline to flush
    wait for CLK_PERIOD * (PIPELINE_DELAY + 2);
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Process ==========
  verify_process : process(clk)
    variable cycle_count : integer := 0;
    variable check_idx : integer := 0;
    variable expected_val : unsigned(7 downto 0);
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Only check after reset
        if rst_n = '1' then
          cycle_count := cycle_count + 1;
          
          -- Start checking after pipeline delay
          if cycle_count > PIPELINE_DELAY and check_idx < NUM_TESTS then
            expected_val := expected_queue(check_idx);
            check_idx := check_idx + 1;
            stats1.checks <= stats1.checks + 1;
            
            -- Check if output matches expected value
            if unsigned(mul_out) /= expected_val then
              stats1.errors <= stats1.errors + 1;
              stats1.errors_mul_out <= stats1.errors_mul_out + 1;
              fail_count <= fail_count + 1;
              
              -- Record first error time
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- Wait for simulation done
    wait until sim_done;
    wait for CLK_PERIOD * 2;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
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
    write(l, stats1.checks);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.checks);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output (mirror file) ==========
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
         integer'image(stats1.checks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.checks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if fail_count = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(fail_count) & " / 100 failures===========");
      check_failed("Test failed: " & integer'image(fail_count) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;