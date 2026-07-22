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
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(63 downto 0) := (others => '0');
  signal B : std_logic_vector(63 downto 0) := (others => '0');
  signal result : std_logic_vector(63 downto 0);
  signal overflow : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_result      : integer;
    errortime_result   : time;
    errors_overflow    : integer;
    errortime_overflow : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_result      => 0,
    errortime_result   => 0 ps,
    errors_overflow    => 0,
    errortime_overflow => 0 ps,
    clocks             => 0
  );
  
  signal test_count : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.sub_64bit
    port map (
      A        => A,
      B        => B,
      result   => result,
      overflow => overflow
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable r : real;
    variable rand_val : std_logic_vector(63 downto 0);
  begin
    sim_done <= false;
    
    -- Run 100 random tests
    for i in 0 to NUM_TESTS-1 loop
      -- Generate random 64-bit A
      for j in 0 to 63 loop
        uniform(seed1, seed2, r);
        if r > 0.5 then
          rand_val(j) := '1';
        else
          rand_val(j) := '0';
        end if;
      end loop;
      A <= rand_val;
      
      -- Generate random 64-bit B
      for j in 0 to 63 loop
        uniform(seed1, seed2, r);
        if r > 0.5 then
          rand_val(j) := '1';
        else
          rand_val(j) := '0';
        end if;
      end loop;
      B <= rand_val;
      
      -- Wait for operation to complete
      wait for 10 ns;
      
      test_count <= i + 1;
    end loop;
    
    -- End simulation
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable expected_result : signed(63 downto 0);
    variable expected_overflow : std_logic;
    variable A_signed : signed(63 downto 0);
    variable B_signed : signed(63 downto 0);
    variable result_signed : signed(63 downto 0);
  begin
    wait for 1 ns; -- Initial delay
    
    while not sim_done loop
      wait for 10 ns;
      
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Convert to signed for calculation
        A_signed := signed(A);
        B_signed := signed(B);
        result_signed := signed(result);
        
        -- Calculate expected result
        expected_result := A_signed - B_signed;
        
        -- Calculate expected overflow
        -- Overflow happens when the sign of A and B are different, 
        -- but the sign of result matches B (or differs from A)
        if (A(63) /= B(63)) and (result(63) /= A(63)) then
          expected_overflow := '1';
        else
          expected_overflow := '0';
        end if;
        
        -- Check result
        if signed(result) /= expected_result then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_result <= stats1.errors_result + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_result = 1 then
            stats1.errortime_result <= now;
          end if;
        end if;
        
        -- Check overflow
        if overflow /= expected_overflow then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_overflow <= stats1.errors_overflow + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_overflow = 1 then
            stats1.errortime_overflow <= now;
          end if;
        end if;
      end if;
    end loop;
    
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
    wait for 100 ns; -- Additional delay to ensure all checks complete
    
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
    
    if stats1.errors_overflow > 0 then
      write(l, string'("Hint: Output 'overflow' has "));
      write(l, stats1.errors_overflow);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_overflow / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'overflow' has no mismatches."));
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
    
    if stats1.errors_overflow > 0 then
      info("Hint: Output 'overflow' has " & integer'image(stats1.errors_overflow) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_overflow / 1 ps) & ".");
    else
      info("Hint: Output 'overflow' has no mismatches.");
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