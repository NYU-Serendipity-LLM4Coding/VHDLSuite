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
  constant PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal reset : std_logic := '1';
  signal up_down : std_logic := '1';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal count : std_logic_vector(15 downto 0);
  
  -- ========== Expected Values ==========
  type result_array_t is array (0 to 2) of unsigned(15 downto 0);
  constant expected_results : result_array_t := (
    0 => to_unsigned(11, 16),
    1 => to_unsigned(65527, 16),
    2 => to_unsigned(21, 16)
  );
  
  constant expected_cases : integer := 3;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_count       : integer;
    errortime_count    : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_count       => 0,
    errortime_count    => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    if not sim_done then
      clk <= '0';
      wait for PERIOD / 2;
      clk <= '1';
      wait for PERIOD / 2;
    else
      wait;
    end if;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.up_down_counter
    port map (
      clk      => clk,
      reset    => reset,
      up_down  => up_down,
      count    => count
    );
  
  -- ========== Stimulus Generation and Verification ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial state: clk = 0; reset = 1; up_down = 1;
    reset <= '1';
    up_down <= '1';
    
    -- #10 reset = 0;
    wait for 10 ns;
    reset <= '0';
    
    -- #20 up_down = 1; (从0ns开始计20ns，所以再等待10ns)
    wait for 10 ns;
    up_down <= '1';
    
    -- #100 up_down = 0; (从20ns开始计，所以再等待100ns)
    wait for 100 ns;
    up_down <= '0';
    
    -- Check first expected value (count should be 11)
    wait for 0 ns;
    if unsigned(count) /= expected_results(0) then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_count <= stats1.errors_count + 1;
      if stats1.errors_count = 1 then
        stats1.errortime <= now;
        stats1.errortime_count <= now;
      end if;
    end if;
    case_num_shared <= 1;
    
    -- #200 up_down = 1; (从120ns开始计，所以再等待200ns)
    wait for 200 ns;
    up_down <= '1';
    
    -- Check second expected value (count should be 65527)
    wait for 0 ns;
    if unsigned(count) /= expected_results(1) then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_count <= stats1.errors_count + 1;
      if stats1.errors_count = 1 then
        stats1.errortime <= now;
        stats1.errortime_count <= now;
      end if;
    end if;
    case_num_shared <= 2;
    
    -- #300; (从320ns开始计，所以再等待300ns)
    wait for 300 ns;
    
    -- Check third expected value (count should be 21)
    wait for 0 ns;
    if unsigned(count) /= expected_results(2) then
      stats1.errors <= stats1.errors + 1;
      stats1.errors_count <= stats1.errors_count + 1;
      if stats1.errors_count = 1 then
        stats1.errortime <= now;
        stats1.errortime_count <= now;
      end if;
    end if;
    case_num_shared <= 3;
    
    wait for 10 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Clock Counter ==========
  verify_process : process(clk)
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    wait until sim_done;
    wait for PERIOD * 2;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- Per-output error statistics
    if stats1.errors_count > 0 then
      write(l, string'("Hint: Output 'count' has "));
      write(l, stats1.errors_count);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_count / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'count' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- MANDATORY THREE LINES
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
    
    file_close(f);
    
    -- Console output
    info("========================================");
    
    if stats1.errors_count > 0 then
      info("Hint: Output 'count' has " & integer'image(stats1.errors_count) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_count / 1 ps) & ".");
    else
      info("Hint: Output 'count' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & " failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;