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
  constant TEST_CASES : integer := 100;
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(15 downto 0) := (others => '0');
  signal B : std_logic_vector(7 downto 0) := (others => '0');
  signal result : std_logic_vector(15 downto 0);
  signal odd : std_logic_vector(15 downto 0);
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_result      : integer;
    errortime_result   : time;
    errors_odd         : integer;
    errortime_odd      : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_result      => 0,
    errortime_result   => 0 ps,
    errors_odd         => 0,
    errortime_odd      => 0 ps,
    clocks             => 0
  );
  
  -- For sharing test case count
  signal case_num_sig : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.div_16bit
    port map (
      A      => A,
      B      => B,
      result => result,
      odd    => odd
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable rand : real;
    variable A_val : integer;
    variable B_val : integer;
    variable expected_result_var : unsigned(15 downto 0);
    variable expected_odd_var : unsigned(15 downto 0);
  begin
    sim_done <= false;
    
    -- Run 100 test cases
    for i in 0 to TEST_CASES - 1 loop
      -- Generate random values
      -- A = $urandom_range(1'b0, 16'b1111_1111_1111_1111);
      uniform(seed1, seed2, rand);
      A_val := integer(rand * 65535.0);
      
      -- B = $urandom_range(1'b1, 8'b1111_1111);
      uniform(seed1, seed2, rand);
      B_val := 1 + integer(rand * 254.0);
      if B_val > 255 then
        B_val := 255;
      end if;
      
      -- Apply inputs
      A <= std_logic_vector(to_unsigned(A_val, 16));
      B <= std_logic_vector(to_unsigned(B_val, 8));
      
      -- Calculate expected values
      expected_result_var := to_unsigned(A_val / B_val, 16);
      expected_odd_var := to_unsigned(A_val mod B_val, 16);
      
      -- Wait for combinational logic to settle
      wait for 10 ns;
      
      -- Increment sample counter
      stats1.clocks <= stats1.clocks + 1;
      
      -- Check results
      if unsigned(result) /= expected_result_var or unsigned(odd) /= expected_odd_var then
        stats1.errors <= stats1.errors + 1;
        
        -- Track first error time
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        
        -- Track result errors
        if unsigned(result) /= expected_result_var then
          stats1.errors_result <= stats1.errors_result + 1;
          if stats1.errors_result = 1 then
            stats1.errortime_result <= now;
          end if;
        end if;
        
        -- Track odd errors
        if unsigned(odd) /= expected_odd_var then
          stats1.errors_odd <= stats1.errors_odd + 1;
          if stats1.errors_odd = 1 then
            stats1.errortime_odd <= now;
          end if;
        end if;
      end if;
      
      case_num_sig <= i + 1;
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
    wait for 2000 ns;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_result > 0 then
      write(l, string'("Hint: Output 'result' has "));
      write(l, stats1.errors_result);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_result / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'result' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_odd > 0 then
      write(l, string'("Hint: Output 'odd' has "));
      write(l, stats1.errors_odd);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_odd / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'odd' has no mismatches."));
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
    
    if stats1.errors_result > 0 then
      info("Hint: Output 'result' has " & integer'image(stats1.errors_result) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_result / 1 ps) & ".");
    else
      info("Hint: Output 'result' has no mismatches.");
    end if;
    
    if stats1.errors_odd > 0 then
      info("Hint: Output 'odd' has " & integer'image(stats1.errors_odd) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_odd / 1 ps) & ".");
    else
      info("Hint: Output 'odd' has no mismatches.");
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
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(stats1.errors) & 
           " /" & integer'image(TEST_CASES) & " failures===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;