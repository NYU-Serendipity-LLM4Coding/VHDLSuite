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
  constant PERIOD : time := 10 ns;  -- From: always #5 clk = ~clk;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal d : std_logic := '0';
  signal q : std_logic_vector(7 downto 0);
  
  -- ========== Expected Values ==========
  constant expected_result : std_logic_vector(7 downto 0) := "11101010";
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_q           : integer;
    errortime_q        : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_q           => 0,
    errortime_q        => 0 ps,
    clocks             => 0
  );
  
  signal verification_done : boolean := false;
  
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
  dut1 : entity work.right_shifter
    port map (
      clk => clk,
      d   => d,
      q   => q
    );
  
  -- ========== Stimulus Generation (from Verilog initial blocks) ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: clk = 0; d = 0;
    d <= '0';
    
    -- From: #20;
    wait for 20 ns;
    
    -- From: d = 1;
    d <= '1';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: d = 0;
    d <= '0';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: d = 1;
    d <= '1';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: d = 0;
    d <= '0';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: d = 1;
    d <= '1';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: d = 1;
    d <= '1';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: d = 1;
    d <= '1';
    
    -- From: #10;
    wait for 10 ns;
    
    -- Check the output at this point
    verification_done <= true;
    wait for 1 ns;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check at the end of stimulus (after all shifts)
        if verification_done then
          if q /= expected_result then
            -- Increment error counters
            stats1.errors <= stats1.errors + 1;
            stats1.errors_q <= stats1.errors_q + 1;
            
            -- Record first error time
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_q = 1 then
              stats1.errortime_q <= now;
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
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_q > 0 then
      write(l, string'("Hint: Output 'q' has "));
      write(l, stats1.errors_q);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_q / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'q' has no mismatches."));
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
    
    if stats1.errors_q > 0 then
      info("Hint: Output 'q' has " & integer'image(stats1.errors_q) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_q / 1 ps) & ".");
    else
      info("Hint: Output 'q' has no mismatches.");
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
      info("===========Failed===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;