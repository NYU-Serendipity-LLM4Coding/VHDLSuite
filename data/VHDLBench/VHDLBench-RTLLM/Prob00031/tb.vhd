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
  constant PERIOD : time := 10 ns;  -- 100MHz input clock
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT outputs
  signal out1 : std_logic;  -- CLK_50
  signal out2 : std_logic;  -- CLK_10
  signal out3 : std_logic;  -- CLK_1
  
  -- ========== Expected Values at specific time points ==========
  type check_point_t is record
    time_point : time;
    exp_out1   : std_logic;
    exp_out2   : std_logic;
    exp_out3   : std_logic;
  end record;
  
  type check_array_t is array (0 to 5) of check_point_t;
  constant expected_checks : check_array_t := (
    0 => (45 ns,  '0', '0', '0'),   -- after reset release
    1 => (55 ns,  '1', '0', '0'),   -- CLK_50 toggled
    2 => (95 ns,  '1', '1', '0'),   -- CLK_10 toggled
    3 => (225 ns, '0', '1', '0'),   -- CLK_50 toggled multiple times
    4 => (625 ns, '0', '1', '1'),   -- CLK_1 toggled
    5 => (1035 ns,'1', '1', '1')    -- all signals toggled
  );
  
  constant expected_cases : integer := 6;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors          : integer;
    errortime       : time;
    errors_out1     : integer;
    errortime_out1  : time;
    errors_out2     : integer;
    errortime_out2  : time;
    errors_out3     : integer;
    errortime_out3  : time;
    clocks          : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors          => 0,
    errortime       => 0 ps,
    errors_out1     => 0,
    errortime_out1  => 0 ps,
    errors_out2     => 0,
    errortime_out2  => 0 ps,
    errors_out3     => 0,
    errortime_out3  => 0 ps,
    clocks          => 0
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
  dut1 : entity work.freq_div
    port map (
      CLK_in  => clk,
      RST     => rst,
      CLK_50  => out1,
      CLK_10  => out2,
      CLK_1   => out3
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial: clk = 0 (done by signal initialization)
    -- #10; (wait 10ns)
    wait for 10 ns;
    
    -- rst = 1;
    rst <= '1';
    
    -- #35; (wait 35ns, total time = 45ns)
    wait for 35 ns;
    
    -- rst = 0;
    rst <= '0';
    
    -- Wait for all check points to complete
    -- Last check is at 1035ns, so wait until 1100ns
    wait for 1060 ns;
    
    -- Finish simulation
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification at Specific Time Points ==========
  verify_process : process
    variable case_num : integer := 0;
    variable check_failed : boolean := false;
  begin
    -- Wait for first check point
    wait for 45 ns;
    
    -- Check point 0: 45ns
    check_failed := false;
    if out1 /= expected_checks(0).exp_out1 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out1 <= stats1.errors_out1 + 1;
      if stats1.errors_out1 = 0 then
        stats1.errortime_out1 <= now;
      end if;
      check_failed := true;
    end if;
    if out2 /= expected_checks(0).exp_out2 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out2 <= stats1.errors_out2 + 1;
      if stats1.errors_out2 = 0 then
        stats1.errortime_out2 <= now;
      end if;
      check_failed := true;
    end if;
    if out3 /= expected_checks(0).exp_out3 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out3 <= stats1.errors_out3 + 1;
      if stats1.errors_out3 = 0 then
        stats1.errortime_out3 <= now;
      end if;
      check_failed := true;
    end if;
    if check_failed and stats1.errors = 1 then
      stats1.errortime <= now;
    end if;
    case_num := case_num + 1;
    case_num_shared <= case_num;
    
    -- Check point 1: 55ns (wait 10ns more)
    wait for 10 ns;
    check_failed := false;
    if out1 /= expected_checks(1).exp_out1 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out1 <= stats1.errors_out1 + 1;
      if stats1.errors_out1 = 0 then
        stats1.errortime_out1 <= now;
      end if;
      check_failed := true;
    end if;
    if out2 /= expected_checks(1).exp_out2 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out2 <= stats1.errors_out2 + 1;
      if stats1.errors_out2 = 0 then
        stats1.errortime_out2 <= now;
      end if;
      check_failed := true;
    end if;
    if out3 /= expected_checks(1).exp_out3 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out3 <= stats1.errors_out3 + 1;
      if stats1.errors_out3 = 0 then
        stats1.errortime_out3 <= now;
      end if;
      check_failed := true;
    end if;
    if check_failed and stats1.errors = 1 then
      stats1.errortime <= now;
    end if;
    case_num := case_num + 1;
    case_num_shared <= case_num;
    
    -- Check point 2: 95ns (wait 40ns more)
    wait for 40 ns;
    check_failed := false;
    if out1 /= expected_checks(2).exp_out1 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out1 <= stats1.errors_out1 + 1;
      if stats1.errors_out1 = 0 then
        stats1.errortime_out1 <= now;
      end if;
      check_failed := true;
    end if;
    if out2 /= expected_checks(2).exp_out2 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out2 <= stats1.errors_out2 + 1;
      if stats1.errors_out2 = 0 then
        stats1.errortime_out2 <= now;
      end if;
      check_failed := true;
    end if;
    if out3 /= expected_checks(2).exp_out3 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out3 <= stats1.errors_out3 + 1;
      if stats1.errors_out3 = 0 then
        stats1.errortime_out3 <= now;
      end if;
      check_failed := true;
    end if;
    if check_failed and stats1.errors = 1 then
      stats1.errortime <= now;
    end if;
    case_num := case_num + 1;
    case_num_shared <= case_num;
    
    -- Check point 3: 225ns (wait 130ns more)
    wait for 130 ns;
    check_failed := false;
    if out1 /= expected_checks(3).exp_out1 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out1 <= stats1.errors_out1 + 1;
      if stats1.errors_out1 = 0 then
        stats1.errortime_out1 <= now;
      end if;
      check_failed := true;
    end if;
    if out2 /= expected_checks(3).exp_out2 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out2 <= stats1.errors_out2 + 1;
      if stats1.errors_out2 = 0 then
        stats1.errortime_out2 <= now;
      end if;
      check_failed := true;
    end if;
    if out3 /= expected_checks(3).exp_out3 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out3 <= stats1.errors_out3 + 1;
      if stats1.errors_out3 = 0 then
        stats1.errortime_out3 <= now;
      end if;
      check_failed := true;
    end if;
    if check_failed and stats1.errors = 1 then
      stats1.errortime <= now;
    end if;
    case_num := case_num + 1;
    case_num_shared <= case_num;
    
    -- Check point 4: 625ns (wait 400ns more)
    wait for 400 ns;
    check_failed := false;
    if out1 /= expected_checks(4).exp_out1 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out1 <= stats1.errors_out1 + 1;
      if stats1.errors_out1 = 0 then
        stats1.errortime_out1 <= now;
      end if;
      check_failed := true;
    end if;
    if out2 /= expected_checks(4).exp_out2 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out2 <= stats1.errors_out2 + 1;
      if stats1.errors_out2 = 0 then
        stats1.errortime_out2 <= now;
      end if;
      check_failed := true;
    end if;
    if out3 /= expected_checks(4).exp_out3 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out3 <= stats1.errors_out3 + 1;
      if stats1.errors_out3 = 0 then
        stats1.errortime_out3 <= now;
      end if;
      check_failed := true;
    end if;
    if check_failed and stats1.errors = 1 then
      stats1.errortime <= now;
    end if;
    case_num := case_num + 1;
    case_num_shared <= case_num;
    
    -- Check point 5: 1035ns (wait 410ns more)
    wait for 410 ns;
    check_failed := false;
    if out1 /= expected_checks(5).exp_out1 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out1 <= stats1.errors_out1 + 1;
      if stats1.errors_out1 = 0 then
        stats1.errortime_out1 <= now;
      end if;
      check_failed := true;
    end if;
    if out2 /= expected_checks(5).exp_out2 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out2 <= stats1.errors_out2 + 1;
      if stats1.errors_out2 = 0 then
        stats1.errortime_out2 <= now;
      end if;
      check_failed := true;
    end if;
    if out3 /= expected_checks(5).exp_out3 then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_out3 <= stats1.errors_out3 + 1;
      if stats1.errors_out3 = 0 then
        stats1.errortime_out3 <= now;
      end if;
      check_failed := true;
    end if;
    if check_failed and stats1.errors = 1 then
      stats1.errortime <= now;
    end if;
    case_num := case_num + 1;
    case_num_shared <= case_num;
    
    wait;
  end process;
  
  -- ========== Clock Counter ==========
  clock_counter : process(clk)
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
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
    -- Wait for simulation to complete
    wait for 1200 ns;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_out1 > 0 then
      write(l, string'("Hint: Output 'CLK_50' has "));
      write(l, stats1.errors_out1);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out1 / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'CLK_50' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out2 > 0 then
      write(l, string'("Hint: Output 'CLK_10' has "));
      write(l, stats1.errors_out2);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out2 / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'CLK_10' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out3 > 0 then
      write(l, string'("Hint: Output 'CLK_1' has "));
      write(l, stats1.errors_out3);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out3 / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'CLK_1' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, expected_cases);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, expected_cases);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_out1 > 0 then
      info("Hint: Output 'CLK_50' has " & integer'image(stats1.errors_out1) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_out1 / 1 ps) & ".");
    else
      info("Hint: Output 'CLK_50' has no mismatches.");
    end if;
    
    if stats1.errors_out2 > 0 then
      info("Hint: Output 'CLK_10' has " & integer'image(stats1.errors_out2) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_out2 / 1 ps) & ".");
    else
      info("Hint: Output 'CLK_10' has no mismatches.");
    end if;
    
    if stats1.errors_out3 > 0 then
      info("Hint: Output 'CLK_1' has " & integer'image(stats1.errors_out3) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_out3 / 1 ps) & ".");
    else
      info("Hint: Output 'CLK_1' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(expected_cases) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(expected_cases) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
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