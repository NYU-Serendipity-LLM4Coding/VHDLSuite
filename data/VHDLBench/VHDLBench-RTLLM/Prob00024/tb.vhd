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
  signal rst : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals (renamed IN to IN_sig to avoid reserved keyword)
  signal IN_sig : std_logic := '0';
  signal MATCH : std_logic;
  
  -- ========== Expected Values (from Verilog testbench checks) ==========
  type result_array_t is array (0 to 11) of std_logic;
  constant expected_results : result_array_t := (
    0 => '0',  -- IN=0
    1 => '0',  -- IN=0
    2 => '0',  -- IN=1
    3 => '0',  -- IN=1
    4 => '0',  -- IN=0
    5 => '0',  -- IN=0
    6 => '0',  -- IN=1
    7 => '1',  -- IN=1 (first match: 10011)
    8 => '0',  -- IN=0
    9 => '0',  -- IN=0
    10 => '0', -- IN=1
    11 => '1'  -- IN=1 (second match: 10011)
  );
  
  constant expected_cases : integer := 12;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_match       : integer;
    errortime_match    : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_match       => 0,
    errortime_match    => 0 ps,
    clocks             => 0
  );
  
  -- For sharing case count
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
  dut1 : entity work.fsm
    port map (
      CLK   => clk,
      RST   => rst,
      IN_p  => IN_sig,
      MATCH => MATCH
    );
  
  -- ========== Stimulus Generation (from Verilog initial blocks) ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: #10; rst =1;
    wait for PERIOD * 1;
    rst <= '1';
    
    -- From: #28; rst = 0;
    wait for 28 ns;
    rst <= '0';
    IN_sig <= '0';
    
    -- From: #10 IN=0;
    wait for PERIOD * 1;
    IN_sig <= '0';
    
    -- From: #10 IN=0;
    wait for PERIOD * 1;
    IN_sig <= '0';
    
    -- From: #10 IN=1;
    wait for PERIOD * 1;
    IN_sig <= '1';
    
    -- From: #10 IN=1;
    wait for PERIOD * 1;
    IN_sig <= '1';
    
    -- From: #10 IN=0;
    wait for PERIOD * 1;
    IN_sig <= '0';
    
    -- From: #10 IN=0;
    wait for PERIOD * 1;
    IN_sig <= '0';
    
    -- From: #10 IN=1;
    wait for PERIOD * 1;
    IN_sig <= '1';
    
    -- From: #10 IN=1;
    wait for PERIOD * 1;
    IN_sig <= '1';
    
    -- From: #10 IN=0;
    wait for PERIOD * 1;
    IN_sig <= '0';
    
    -- From: #10 IN=0;
    wait for PERIOD * 1;
    IN_sig <= '0';
    
    -- From: #10 IN=1;
    wait for PERIOD * 1;
    IN_sig <= '1';
    
    -- From: #10 IN=1;
    wait for PERIOD * 1;
    IN_sig <= '1';
    
    -- Wait a bit before finishing
    wait for PERIOD * 2;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Start checking after reset is deasserted (after 38ns total)
        -- The first check happens at 48ns (38+10)
        if rst = '0' and now >= 48 ns and case_num < expected_cases then
          -- Check MATCH against expected value
          if MATCH /= expected_results(case_num) then
            -- Increment error counters
            stats1.errors <= stats1.errors + 1;
            stats1.errors_match <= stats1.errors_match + 1;
            
            -- Record first error time
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_match = 1 then
              stats1.errortime_match <= now;
            end if;
          end if;
          
          -- Increment case counter
          case_num := case_num + 1;
          case_num_shared <= case_num;
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_match > 0 then
      write(l, string'("Hint: Output 'MATCH' has "));
      write(l, stats1.errors_match);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_match / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'MATCH' has no mismatches."));
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
    
    if stats1.errors_match > 0 then
      info("Hint: Output 'MATCH' has " & integer'image(stats1.errors_match) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_match / 1 ps) & ".");
    else
      info("Hint: Output 'MATCH' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;