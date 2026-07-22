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
  signal clk : std_logic := '1';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal clk_div : std_logic;
  
  -- ========== Expected Values (Corrected) ==========
  type expected_array_t is array (0 to 18) of std_logic;
  constant expected_results : expected_array_t := (
    0 => '1',  -- i=1: t=15ns
    1 => '1',  -- i=2: t=20ns
    2 => '1',  -- i=3: t=25ns
    3 => '1',  -- i=4: t=30ns
    4 => '1',  -- i=5: t=35ns (FIXED: was '0')
    5 => '0',  -- i=6: t=40ns
    6 => '0',  -- i=7: t=45ns
    7 => '0',  -- i=8: t=50ns
    8 => '0',  -- i=9: t=55ns
    9 => '0',  -- i=10: t=60ns (FIXED: was '1')
    10 => '1', -- i=11: t=65ns
    11 => '1', -- i=12: t=70ns
    12 => '1', -- i=13: t=75ns
    13 => '1', -- i=14: t=80ns
    14 => '1', -- i=15: t=85ns (FIXED: was '0')
    15 => '0', -- i=16: t=90ns
    16 => '0', -- i=17: t=95ns
    17 => '0', -- i=18: t=100ns
    18 => '0'  -- i=19: t=105ns
  );
  
  constant expected_cases : integer := 19;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_clk_div     : integer;
    errortime_clk_div  : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_clk_div     => 0,
    errortime_clk_div  => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    while not sim_done loop
      clk <= '1';
      wait for PERIOD / 2;
      clk <= '0';
      wait for PERIOD / 2;
    end loop;
    wait;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.freq_divbyodd
    port map (
      clk     => clk,
      rst_n   => rst_n,
      clk_div => clk_div
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    rst_n <= '0';
    wait for 10 ns;
    rst_n <= '1';
    
    wait for 120 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable case_num : integer := 0;
  begin
    wait for 15 ns;
    
    for i in 0 to 18 loop
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        if clk_div /= expected_results(i) then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_clk_div <= stats1.errors_clk_div + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_clk_div = 1 then
            stats1.errortime_clk_div <= now;
          end if;
        end if;
        
        case_num := case_num + 1;
        case_num_shared <= case_num;
      end if;
      
      wait for 5 ns;
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
    wait until sim_done;
    wait for PERIOD * 2;
    
    -- Per-output error statistics
    if stats1.errors_clk_div > 0 then
      write(l, string'("Hint: Output 'clk_div' has "));
      write(l, stats1.errors_clk_div);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_clk_div / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'clk_div' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Mandatory three lines
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
    
    if stats1.errors_clk_div > 0 then
      info("Hint: Output 'clk_div' has " & integer'image(stats1.errors_clk_div) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_clk_div / 1 ps) & ".");
    else
      info("Hint: Output 'clk_div' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & 
           "/" & integer'image(expected_cases) & " failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;