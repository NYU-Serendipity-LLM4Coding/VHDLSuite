-- (1) Testbench with integrated stimulus (tb entity)
-- VUnit framework + stimulus generation + verification against expected values
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
  -- ========== Constants (from Verilog parameters) ==========
  constant PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal data_in : std_logic := '1';
  signal sequence_detected : std_logic;
  
  -- ========== Expected Values ==========
  type expected_array_t is array (0 to 2) of std_logic;
  constant expected_results : expected_array_t := (
    0 => '1',  -- After first 1001 sequence
    1 => '0',  -- After 10
    2 => '1'   -- After 1001 sequence again
  );
  
  constant expected_cases : integer := 3;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors                  : integer;
    errortime               : time;
    errors_sequence_detected : integer;
    errortime_sequence_detected : time;
    clocks                  : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors                  => 0,
    errortime               => 0 ps,
    errors_sequence_detected => 0,
    errortime_sequence_detected => 0 ps,
    clocks                  => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '0';
    wait for PERIOD / 2;
    clk <= '1';
    wait for PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.sequence_detector
    port map (
      clk                => clk,
      rst_n              => rst_n,
      data_in            => data_in,
      sequence_detected  => sequence_detected
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: #2 rst_n = 1;
    wait for 2 ns;
    rst_n <= '1';
    
    -- From: #6 data_in = 1;
    wait for 6 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10; data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10; data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10;
    wait for 10 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable case_num : integer := 0;
  begin
    -- Wait for initial reset and setup
    wait for 58 ns;  -- Position at first check point
    
    -- Check 1: After first 1001 sequence
    wait for 0 ns;
    if not sim_done then
      stats1.clocks <= stats1.clocks + 1;
      if sequence_detected /= expected_results(case_num) then
        stats1.errors <= stats1.errors + 1;
        stats1.errors_sequence_detected <= stats1.errors_sequence_detected + 1;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        if stats1.errors_sequence_detected = 1 then
          stats1.errortime_sequence_detected <= now;
        end if;
      end if;
      case_num := case_num + 1;
      case_num_shared <= case_num;
    end if;
    
    -- Wait to second check point
    wait for 20 ns;  -- At 78ns, after data_in = 0
    
    -- Check 2: After 10
    if not sim_done then
      stats1.clocks <= stats1.clocks + 1;
      if sequence_detected /= expected_results(case_num) then
        stats1.errors <= stats1.errors + 1;
        stats1.errors_sequence_detected <= stats1.errors_sequence_detected + 1;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        if stats1.errors_sequence_detected = 1 then
          stats1.errortime_sequence_detected <= now;
        end if;
      end if;
      case_num := case_num + 1;
      case_num_shared <= case_num;
    end if;
    
    -- Wait to third check point
    wait for 30 ns;  -- At 108ns, after second 1001
    
    -- Check 3: After second 1001 sequence
    if not sim_done then
      stats1.clocks <= stats1.clocks + 1;
      if sequence_detected /= expected_results(case_num) then
        stats1.errors <= stats1.errors + 1;
        stats1.errors_sequence_detected <= stats1.errors_sequence_detected + 1;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        if stats1.errors_sequence_detected = 1 then
          stats1.errortime_sequence_detected <= now;
        end if;
      end if;
      case_num := case_num + 1;
      case_num_shared <= case_num;
    end if;
    
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_sequence_detected > 0 then
      write(l, string'("Hint: Output 'sequence_detected' has "));
      write(l, stats1.errors_sequence_detected);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_sequence_detected / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'sequence_detected' has no mismatches."));
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
    
    if stats1.errors_sequence_detected > 0 then
      info("Hint: Output 'sequence_detected' has " & integer'image(stats1.errors_sequence_detected) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_sequence_detected / 1 ps) & ".");
    else
      info("Hint: Output 'sequence_detected' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & " /100 failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;