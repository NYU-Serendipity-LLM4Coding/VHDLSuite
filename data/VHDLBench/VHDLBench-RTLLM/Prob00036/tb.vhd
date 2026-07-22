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
  -- ========== Constants ==========
  constant CLK_PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '1';
  signal a : std_logic := '0';
  signal rise : std_logic;
  signal down : std_logic;
  signal sim_done : boolean := false;
  
  -- ========== Expected Values ==========
  type test_case_t is record
    expected_rise : std_logic;
    expected_down : std_logic;
  end record;
  
  type test_array_t is array (0 to 3) of test_case_t;
  constant expected_results : test_array_t := (
    0 => (expected_rise => '0', expected_down => '0'),  -- No edge
    1 => (expected_rise => '1', expected_down => '0'),  -- Rising edge
    2 => (expected_rise => '0', expected_down => '1'),  -- Falling edge
    3 => (expected_rise => '0', expected_down => '0')   -- After reset
  );
  
  constant expected_cases : integer := 4;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_rise        : integer;
    errortime_rise     : time;
    errors_down        : integer;
    errortime_down     : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_rise        => 0,
    errortime_rise     => 0 ps,
    errors_down        => 0,
    errortime_down     => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  signal check_enable : std_logic := '0';
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.edge_detect
    port map (
      clk   => clk,
      rst_n => rst_n,
      a     => a,
      rise  => rise,
      down  => down
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    check_enable <= '0';
    
    -- Initialize inputs
    clk <= '0';
    rst_n <= '1';
    a <= '0';
    
    -- Wait for a few clock cycles to ensure the module stabilizes
    wait for 5 ns;
    
    -- Test scenario 1: No edge
    a <= '0';
    wait for 10 ns;
    a <= '0';
    wait for 10 ns;
    check_enable <= '1';
    wait for 1 ns;
    check_enable <= '0';
    
    -- Test scenario 2: Rising edge
    a <= '0';
    wait for 10 ns;
    a <= '1';
    wait for 10 ns;
    a <= '1';
    check_enable <= '1';
    wait for 1 ns;
    check_enable <= '0';
    
    -- Test scenario 3: Falling edge
    a <= '1';
    wait for 10 ns;
    a <= '0';
    wait for 10 ns;
    a <= '0';
    check_enable <= '1';
    wait for 1 ns;
    check_enable <= '0';
    
    -- Test scenario 4: Reset
    rst_n <= '0';
    wait for 10 ns;
    rst_n <= '1';
    wait for 10 ns;
    check_enable <= '1';
    wait for 1 ns;
    check_enable <= '0';
    
    wait for 10 ns;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check on check_enable pulse
        if check_enable = '1' and case_num < expected_cases then
          -- Check rise signal
          if rise /= expected_results(case_num).expected_rise then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_rise <= stats1.errors_rise + 1;
            if stats1.errors_rise = 1 then
              stats1.errortime_rise <= now;
            end if;
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
          end if;
          
          -- Check down signal
          if down /= expected_results(case_num).expected_down then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_down <= stats1.errors_down + 1;
            if stats1.errors_down = 1 then
              stats1.errortime_down <= now;
            end if;
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
          end if;
          
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
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_rise > 0 then
      write(l, string'("Hint: Output 'rise' has "));
      write(l, stats1.errors_rise);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_rise / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'rise' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_down > 0 then
      write(l, string'("Hint: Output 'down' has "));
      write(l, stats1.errors_down);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_down / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'down' has no mismatches."));
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
    
    if stats1.errors_rise > 0 then
      info("Hint: Output 'rise' has " & integer'image(stats1.errors_rise) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_rise / 1 ps) & ".");
    else
      info("Hint: Output 'rise' has no mismatches.");
    end if;
    
    if stats1.errors_down > 0 then
      info("Hint: Output 'down' has " & integer'image(stats1.errors_down) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_down / 1 ps) & ".");
    else
      info("Hint: Output 'down' has no mismatches.");
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
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;