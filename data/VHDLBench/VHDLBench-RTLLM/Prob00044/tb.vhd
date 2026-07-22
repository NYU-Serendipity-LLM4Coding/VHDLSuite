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
  constant CHECK_INTERVAL : time := 5 ns;  -- From: #5 in testbench
  
  -- ========== Signals ==========
  signal clk_dut : std_logic;
  signal sim_done : boolean := false;
  
  -- Expected value tracking
  signal res : std_logic := '0';
  
  -- ========== Statistics ==========
  type stats_t is record
    errors          : integer;
    errortime       : time;
    errors_clk      : integer;
    errortime_clk   : time;
    clocks          : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors          => 0,
    errortime       => 0 ps,
    errors_clk      => 0,
    errortime_clk   => 0 ps,
    clocks          => 0
  );
  
  constant expected_samples : integer := 20;
  signal case_num_shared : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.clkgenerator
    port map (
      clk => clk_dut
    );
  
  -- ========== Stimulus and Verification Process ==========
  -- From: repeat (20) begin #5; error = (res == clk_tb) ? error : error+1; res = res + 1; end
  stimulus_verify_process : process
    variable sample_count : integer := 0;
  begin
    sim_done <= false;
    res <= '0';
    
    -- Simulate 20 samples with 5ns interval
    for i in 0 to 19 loop
      wait for CHECK_INTERVAL;
      
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        sample_count := sample_count + 1;
        
        -- Check: error = (res == clk_tb) ? error : error+1;
        if res /= clk_dut then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_clk <= stats1.errors_clk + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_clk = 1 then
            stats1.errortime_clk <= now;
          end if;
        end if;
        
        -- Update expected value: res = res + 1 (toggle)
        res <= not res;
        case_num_shared <= sample_count;
      end if;
    end loop;
    
    -- From: $finish;
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_clk > 0 then
      write(l, string'("Hint: Output 'clk' has "));
      write(l, stats1.errors_clk);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_clk / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'clk' has no mismatches."));
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
    
    if stats1.errors_clk > 0 then
      info("Hint: Output 'clk' has " & integer'image(stats1.errors_clk) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_clk / 1 ps) & ".");
    else
      info("Hint: Output 'clk' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    -- From: if (error == 0) $display("...Passed...");
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & " failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;