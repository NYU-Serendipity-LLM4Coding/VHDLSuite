-- 8-bit multiplier testbench with shift-and-add verification
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  -- ========== Constants ==========
  constant PERIOD : time := 10 ns;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(7 downto 0) := (others => '0');
  signal B : std_logic_vector(7 downto 0) := (others => '0');
  signal product : std_logic_vector(15 downto 0);
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_product     : integer;
    errortime_product  : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_product     => 0,
    errortime_product  => 0 ps,
    clocks             => 0
  );
  
  -- For sharing test count (use signal instead of shared variable)
  signal test_count_shared : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.multi_8bit
    port map (
      A       => A,
      B       => B,
      product => product
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable A_val : integer;
    variable B_val : integer;
  begin
    sim_done <= false;
    
    -- Generate 100 random test cases
    for i in 0 to NUM_TESTS - 1 loop
      -- Generate pseudo-random 8-bit values using simple LFSR-like formula
      A_val := (i * 17 + 42) mod 256;
      B_val := (i * 23 + 13) mod 256;
      
      A <= std_logic_vector(to_unsigned(A_val, 8));
      B <= std_logic_vector(to_unsigned(B_val, 8));
      
      -- Wait for operation to complete
      wait for PERIOD;
    end loop;
    
    -- Additional wait before ending
    wait for PERIOD * 2;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable test_num : integer := 0;
    variable expected_product : unsigned(15 downto 0);
    variable A_unsigned : unsigned(7 downto 0);
    variable B_unsigned : unsigned(7 downto 0);
  begin
    -- Wait for first stimulus
    wait for PERIOD;
    
    for i in 0 to NUM_TESTS - 1 loop
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Calculate expected product (A * B)
        A_unsigned := unsigned(A);
        B_unsigned := unsigned(B);
        expected_product := A_unsigned * B_unsigned;
        
        -- Check product against expected value
        if unsigned(product) /= expected_product then
          -- Increment error counters
          stats1.errors <= stats1.errors + 1;
          stats1.errors_product <= stats1.errors_product + 1;
          
          -- Record first error time
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_product = 1 then
            stats1.errortime_product <= now;
          end if;
        end if;
        
        test_num := test_num + 1;
        test_count_shared <= test_num;  -- Update signal
        
        wait for PERIOD;
      else
        exit;
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
    wait for PERIOD * (NUM_TESTS + 10);
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_product > 0 then
      write(l, string'("Hint: Output 'product' has "));
      write(l, stats1.errors_product);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_product / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'product' has no mismatches."));
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
    
    if stats1.errors_product > 0 then
      info("Hint: Output 'product' has " & integer'image(stats1.errors_product) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_product / 1 ps) & ".");
    else
      info("Hint: Output 'product' has no mismatches.");
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