-- (1) Testbench with integrated stimulus (tb entity)
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
  signal rst_n : std_logic := '1';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal pass_request : std_logic := '0';
  signal clock_out : std_logic_vector(7 downto 0);
  signal red : std_logic;
  signal yellow : std_logic;
  signal green : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    clocks             => 0
  );
  
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
  dut1 : entity work.traffic_light
    port map (
      clk          => clk,
      rst_n        => rst_n,
      pass_request => pass_request,
      clock        => clock_out,
      red          => red,
      yellow       => yellow,
      green        => green
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable clock_cnt_var : integer := 0;
    variable error_count : integer := 0;  -- Local variable for error counting
  begin
    sim_done <= false;
    
    -- Initialize
    rst_n <= '1';
    pass_request <= '0';
    
    -- Perform reset
    rst_n <= '0';
    wait for 10 ns;
    rst_n <= '1';
    wait for 30 ns;
    
    -- Test 1: red light
    info("At time " & integer'image(now / 1 ns) & "ns, clock = " & 
         integer'image(to_integer(unsigned(clock_out))) & 
         ", red = " & std_logic'image(red) & 
         ", yellow = " & std_logic'image(yellow) & 
         ", green = " & std_logic'image(green));
    
    if not ((red = '1') and (yellow = '0') and (green = '0')) then
      error_count := error_count + 1;
      info("ERROR: Expected red=1, yellow=0, green=0");
    end if;
    wait for 100 ns;
    
    -- Test 2: green light
    info("At time " & integer'image(now / 1 ns) & "ns, clock = " & 
         integer'image(to_integer(unsigned(clock_out))) & 
         ", red = " & std_logic'image(red) & 
         ", yellow = " & std_logic'image(yellow) & 
         ", green = " & std_logic'image(green));
    
    if not ((red = '0') and (yellow = '0') and (green = '1')) then
      error_count := error_count + 1;
      info("ERROR: Expected red=0, yellow=0, green=1");
    end if;
    wait for 600 ns;
    
    -- Test 3: yellow light
    info("At time " & integer'image(now / 1 ns) & "ns, clock = " & 
         integer'image(to_integer(unsigned(clock_out))) & 
         ", red = " & std_logic'image(red) & 
         ", yellow = " & std_logic'image(yellow) & 
         ", green = " & std_logic'image(green));
    
    if not ((red = '0') and (yellow = '1') and (green = '0')) then
      error_count := error_count + 1;
      info("ERROR: Expected red=0, yellow=1, green=0");
    end if;
    wait for 150 ns;
    
    -- Save clock count
    info("At time " & integer'image(now / 1 ns) & "ns, clock = " & 
         integer'image(to_integer(unsigned(clock_out))) & 
         ", red = " & std_logic'image(red) & 
         ", yellow = " & std_logic'image(yellow) & 
         ", green = " & std_logic'image(green));
    clock_cnt_var := to_integer(unsigned(clock_out));
    
    -- Test 4: counter decrement check
    wait for 30 ns;
    info("At time " & integer'image(now / 1 ns) & "ns, clock = " & 
         integer'image(to_integer(unsigned(clock_out))) & 
         ", red = " & std_logic'image(red) & 
         ", yellow = " & std_logic'image(yellow) & 
         ", green = " & std_logic'image(green));
    
    -- CRITICAL FIX: Verilog checks (clock != clock_cnt+3) is PASS
    -- So (clock == clock_cnt+3) is FAIL
    -- Counter should DECREASE, not increase!
    if to_integer(unsigned(clock_out)) = (clock_cnt_var + 3) then
      error_count := error_count + 1;
      info("ERROR: Clock should decrease, not increase. Expected NOT " & 
           integer'image(clock_cnt_var + 3) & 
           ", got " & integer'image(to_integer(unsigned(clock_out))));
    end if;
    
    -- Test 5: pass_request functionality
    pass_request <= '1';
    wait for 10 ns;
    info("At time " & integer'image(now / 1 ns) & "ns, clock = " & 
         integer'image(to_integer(unsigned(clock_out))) & 
         ", red = " & std_logic'image(red) & 
         ", yellow = " & std_logic'image(yellow) & 
         ", green = " & std_logic'image(green));
    
    if not ((to_integer(unsigned(clock_out)) = 10) and (green = '1')) then
      error_count := error_count + 1;
      info("ERROR: Expected clock=10 and green=1, got clock=" & 
           integer'image(to_integer(unsigned(clock_out))) & 
           " green=" & std_logic'image(green));
    end if;
    
    -- Update signal with final error count
    stats1.errors <= error_count;
    
    wait for 100 ns;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification ==========
  verify_process : process(clk)
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
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
    -- CRITICAL: Wait for sim_done, NOT fixed time
    wait until sim_done;
    wait for PERIOD * 2;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- ========== Write to summary.txt ==========
    
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
      info("===========Failed===========" & integer'image(stats1.errors));
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;