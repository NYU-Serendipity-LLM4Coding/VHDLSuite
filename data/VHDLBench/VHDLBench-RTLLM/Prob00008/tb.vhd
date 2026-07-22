-- VHDL 2008 Testbench for 4-bit Comparator
-- Translated from Verilog testbench with VUnit framework

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
  constant WAIT_TIME : time := 10 ns;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(3 downto 0) := (others => '0');
  signal B : std_logic_vector(3 downto 0) := (others => '0');
  signal A_greater : std_logic;
  signal A_equal : std_logic;
  signal A_less : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_A_greater   : integer;
    errortime_A_greater : time;
    errors_A_equal     : integer;
    errortime_A_equal  : time;
    errors_A_less      : integer;
    errortime_A_less   : time;
    samples            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_A_greater   => 0,
    errortime_A_greater => 0 ps,
    errors_A_equal     => 0,
    errortime_A_equal  => 0 ps,
    errors_A_less      => 0,
    errortime_A_less   => 0 ps,
    samples            => 0
  );
  
  signal test_index : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.comparator_4bit
    port map (
      A         => A,
      B         => B,
      A_greater => A_greater,
      A_equal   => A_equal,
      A_less    => A_less
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1, seed2 : positive := 1;
    variable rand_val : real;
    variable A_int, B_int : integer;
  begin
    sim_done <= false;
    
    -- Loop for 100 random test cases
    for i in 0 to NUM_TESTS - 1 loop
      
      -- Generate random 4-bit inputs (0 to 15)
      uniform(seed1, seed2, rand_val);
      A_int := integer(floor(rand_val * 16.0));
      A <= std_logic_vector(to_unsigned(A_int, 4));
      
      uniform(seed1, seed2, rand_val);
      B_int := integer(floor(rand_val * 16.0));
      B <= std_logic_vector(to_unsigned(B_int, 4));
      
      test_index <= i;
      
      -- Wait for the combinational logic to settle
      wait for WAIT_TIME;
      
    end loop;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Process ==========
  verify_process : process
    variable A_val, B_val : unsigned(3 downto 0);
    variable expected_greater, expected_equal, expected_less : std_logic;
    variable error_this_cycle : boolean;
  begin
    wait for 1 ps;  -- Initial offset
    
    for i in 0 to NUM_TESTS - 1 loop
      
      wait for WAIT_TIME;
      
      if not sim_done then
        
        -- Get values for comparison
        A_val := unsigned(A);
        B_val := unsigned(B);
        
        -- Calculate expected results
        if A_val > B_val then
          expected_greater := '1';
          expected_equal := '0';
          expected_less := '0';
        elsif A_val = B_val then
          expected_greater := '0';
          expected_equal := '1';
          expected_less := '0';
        else
          expected_greater := '0';
          expected_equal := '0';
          expected_less := '1';
        end if;
        
        error_this_cycle := false;
        
        -- Check A_greater
        if A_greater /= expected_greater then
          if stats1.errors_A_greater = 0 then
            stats1.errortime_A_greater <= now;
          end if;
          stats1.errors_A_greater <= stats1.errors_A_greater + 1;
          error_this_cycle := true;
        end if;
        
        -- Check A_equal
        if A_equal /= expected_equal then
          if stats1.errors_A_equal = 0 then
            stats1.errortime_A_equal <= now;
          end if;
          stats1.errors_A_equal <= stats1.errors_A_equal + 1;
          error_this_cycle := true;
        end if;
        
        -- Check A_less
        if A_less /= expected_less then
          if stats1.errors_A_less = 0 then
            stats1.errortime_A_less <= now;
          end if;
          stats1.errors_A_less <= stats1.errors_A_less + 1;
          error_this_cycle := true;
        end if;
        
        -- Count overall errors
        if error_this_cycle then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        stats1.samples <= stats1.samples + 1;
        
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- Wait for simulation to complete
    wait for 2000 ns;
    
    -- ========== Write summary.txt ==========
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- Per-output error statistics
    if stats1.errors_A_greater > 0 then
      write(l, string'("Hint: Output 'A_greater' has "));
      write(l, stats1.errors_A_greater);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_A_greater / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'A_greater' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_A_equal > 0 then
      write(l, string'("Hint: Output 'A_equal' has "));
      write(l, stats1.errors_A_equal);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_A_equal / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'A_equal' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_A_less > 0 then
      write(l, string'("Hint: Output 'A_less' has "));
      write(l, stats1.errors_A_less);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_A_less / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'A_less' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- MANDATORY THREE LINES
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, NUM_TESTS);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, NUM_TESTS);
    write(l, string'(" samples"));
    writeline(f, l);
    
    file_close(f);
    
    -- ========== Console output ==========
    info("========================================");
    
    if stats1.errors_A_greater > 0 then
      info("Hint: Output 'A_greater' has " & integer'image(stats1.errors_A_greater) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_A_greater / 1 ps) & ".");
    else
      info("Hint: Output 'A_greater' has no mismatches.");
    end if;
    
    if stats1.errors_A_equal > 0 then
      info("Hint: Output 'A_equal' has " & integer'image(stats1.errors_A_equal) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_A_equal / 1 ps) & ".");
    else
      info("Hint: Output 'A_equal' has no mismatches.");
    end if;
    
    if stats1.errors_A_less > 0 then
      info("Hint: Output 'A_less' has " & integer'image(stats1.errors_A_less) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_A_less / 1 ps) & ".");
    else
      info("Hint: Output 'A_less' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(NUM_TESTS) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(NUM_TESTS) & " samples");
    
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & 
           " /" & integer'image(NUM_TESTS) & " failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;