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
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(2 downto 0) := (others => '0');
  signal B : std_logic_vector(2 downto 0) := (others => '0');
  signal A_greater : std_logic;
  signal A_equal : std_logic;
  signal A_less : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors : integer;
    errortime : time;
    samples : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors => 0,
    errortime => 0 ps,
    samples => 0
  );
  
  -- For sharing error count with report process
  signal error_count : integer := 0;
  
  -- LFSR for pseudo-random generation (mimics $random % 8)
  signal lfsr : unsigned(15 downto 0) := x"ACE1";
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.comparator_3bit
    port map (
      A => A,
      B => B,
      A_greater => A_greater,
      A_equal => A_equal,
      A_less => A_less
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable A_int : integer;
    variable B_int : integer;
    variable expected_greater : std_logic;
    variable expected_equal : std_logic;
    variable expected_less : std_logic;
    variable local_lfsr : unsigned(15 downto 0) := x"ACE1";
  begin
    sim_done <= false;
    
    -- Loop for 100 test cases (from: for (i = 0; i < 100; i = i + 1))
    for i in 0 to 99 loop
      -- Generate random 3-bit inputs (from: A = $random % 8; B = $random % 8;)
      -- Simple LFSR-based random generation
      local_lfsr := local_lfsr(14 downto 0) & (local_lfsr(15) xor local_lfsr(13) xor local_lfsr(12) xor local_lfsr(10));
      A_int := to_integer(local_lfsr(2 downto 0));
      local_lfsr := local_lfsr(14 downto 0) & (local_lfsr(15) xor local_lfsr(13) xor local_lfsr(12) xor local_lfsr(10));
      B_int := to_integer(local_lfsr(2 downto 0));
      
      A <= std_logic_vector(to_unsigned(A_int, 3));
      B <= std_logic_vector(to_unsigned(B_int, 3));
      
      -- Wait for operation to complete (from: #10;)
      wait for PERIOD;
      
      -- Calculate expected results
      if A_int > B_int then
        expected_greater := '1';
        expected_equal := '0';
        expected_less := '0';
      elsif A_int = B_int then
        expected_greater := '0';
        expected_equal := '1';
        expected_less := '0';
      else
        expected_greater := '0';
        expected_equal := '0';
        expected_less := '1';
      end if;
      
      -- Check results (from: if ((A > B && !A_greater) || (A == B && !A_equal) || (A < B && !A_less)))
      if (A_greater /= expected_greater) or 
         (A_equal /= expected_equal) or 
         (A_less /= expected_less) then
        stats1.errors <= stats1.errors + 1;
        error_count <= error_count + 1;
        
        if stats1.errors = 0 then
          stats1.errortime <= now;
        end if;
        
        info("Test failed: A = " & to_string(A) & 
             ", B = " & to_string(B) & 
             ", A_greater = " & std_logic'image(A_greater) & 
             ", A_equal = " & std_logic'image(A_equal) & 
             ", A_less = " & std_logic'image(A_less));
      end if;
      
      stats1.samples <= stats1.samples + 1;
    end loop;
    
    -- End simulation (from: $finish;)
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
    wait for 1100 ns;  -- 100 tests * 10ns + margin
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors > 0 then
      write(l, string'("Hint: Comparison outputs have "));
      write(l, stats1.errors);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: All comparison outputs are correct."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.samples);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.samples);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors > 0 then
      info("Hint: Comparison outputs have " & integer'image(stats1.errors) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime / 1 ps) & ".");
    else
      info("Hint: All comparison outputs are correct.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.samples) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.samples) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    -- From: if (error == 0) $display("...Passed...");
    if error_count = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(error_count) & 
           " /100 failures ===========");
      check_failed("Test failed: " & integer'image(error_count) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;