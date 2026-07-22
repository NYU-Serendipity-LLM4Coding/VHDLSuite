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
  -- ========== Constants (from Verilog parameters) ==========
  constant Q : integer := 15;
  constant N : integer := 32;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(N-1 downto 0) := (others => '0');
  signal b : std_logic_vector(N-1 downto 0) := (others => '0');
  signal c : std_logic_vector(N-1 downto 0);
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_c           : integer;
    errortime_c        : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_c           => 0,
    errortime_c        => 0 ps,
    clocks             => 0
  );
  
  signal test_count : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.fixed_point_adder
    generic map (
      Q => Q,
      N => N
    )
    port map (
      a => a,
      b => b,
      c => c
    );
  
  -- ========== Stimulus and Verification ==========
  stimulus_process : process
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable rand_val : real;
    variable rand_int : integer;
    variable a_val, b_val : std_logic_vector(N-1 downto 0);
    variable expected_result : std_logic_vector(N-1 downto 0);
    variable a_abs, b_abs : unsigned(N-2 downto 0);
    variable res_abs : unsigned(N-2 downto 0);
    variable temp_unsigned : unsigned(N-1 downto 0);
  begin
    sim_done <= false;
    
    -- Run 100 random tests
    for i in 0 to NUM_TESTS-1 loop
      -- Generate random values for a
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * real(2**30)));
      if rand_int < 0 then
        rand_int := -rand_int;
      end if;
      a_val := std_logic_vector(to_unsigned(rand_int, N));
      
      -- Generate random values for b
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * real(2**30)));
      if rand_int < 0 then
        rand_int := -rand_int;
      end if;
      b_val := std_logic_vector(to_unsigned(rand_int, N));
      
      a <= a_val;
      b <= b_val;
      
      wait for 10 ns;
      
      -- Calculate expected result based on testbench logic
      a_abs := unsigned(a_val(N-2 downto 0));
      b_abs := unsigned(b_val(N-2 downto 0));
      
      -- Determine expected result based on sign bits and magnitudes
      if (a_val(N-1) = b_val(N-1)) or 
         (a_val(N-1) = '0' and b_val(N-1) = '1' and a_abs >= b_abs) or
         (a_val(N-1) = '1' and b_val(N-1) = '0' and a_abs < b_abs) then
        -- Addition case
        temp_unsigned := unsigned(a_val) + unsigned(b_val);
        expected_result := std_logic_vector(temp_unsigned);
      elsif a_val(N-1) = '0' and b_val(N-1) = '1' and a_abs < b_abs then
        -- b - a case
        temp_unsigned := unsigned(b_val) - unsigned(a_val);
        expected_result := std_logic_vector(temp_unsigned);
      else
        -- a - b case
        temp_unsigned := unsigned(a_val) - unsigned(b_val);
        expected_result := std_logic_vector(temp_unsigned);
      end if;
      
      -- Verify output
      stats1.clocks <= stats1.clocks + 1;
      test_count <= test_count + 1;
      
      if c /= expected_result then
        stats1.errors <= stats1.errors + 1;
        stats1.errors_c <= stats1.errors_c + 1;
        
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        if stats1.errors_c = 1 then
          stats1.errortime_c <= now;
        end if;
      end if;
      
    end loop;
    
    sim_done <= true;
    wait;
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
    -- Wait for simulation to complete
    wait until sim_done;
    wait for 100 ns;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_c > 0 then
      write(l, string'("Hint: Output 'c' has "));
      write(l, stats1.errors_c);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_c / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'c' has no mismatches."));
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
    
    -- ========== Console Output (mirror file) ==========
    info("========================================");
    
    if stats1.errors_c > 0 then
      info("Hint: Output 'c' has " & integer'image(stats1.errors_c) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_c / 1 ps) & ".");
    else
      info("Hint: Output 'c' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & 
           " /" & integer'image(NUM_TESTS) & " failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;