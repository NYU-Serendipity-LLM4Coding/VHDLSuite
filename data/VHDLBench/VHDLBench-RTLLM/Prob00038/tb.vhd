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
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal data_in : std_logic := '0';
  signal data_out : std_logic;
  
  -- ========== Expected Values ==========
  type result_array_t is array (0 to 9) of std_logic;
  constant expected_results : result_array_t := (
    0 => '0',  -- at 15ns
    1 => '0',  -- at 25ns
    2 => '0',  -- at 35ns
    3 => '0',  -- at 45ns
    4 => '0',  -- at 55ns
    5 => '0',  -- at 65ns
    6 => '0',  -- at 75ns
    7 => '0',  -- at 85ns
    8 => '1',  -- at 95ns (pulse detected)
    9 => '1'   -- at 115ns (pulse detected)
  );
  
  constant expected_cases : integer := 10;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_data_out    : integer;
    errortime_data_out : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_data_out    => 0,
    errortime_data_out => 0 ps,
    clocks             => 0
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
  dut1 : entity work.pulse_detect
    port map (
      clk      => clk,
      rst_n    => rst_n,
      data_in  => data_in,
      data_out => data_out
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: #10; rst_n = 0; data_in = 0;
    wait for 10 ns;
    rst_n <= '0';
    data_in <= '0';
    
    -- From: #28; rst_n = 1;
    wait for 28 ns;
    rst_n <= '1';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 1;
    wait for 10 ns;
    data_in <= '1';
    
    -- From: #10 data_in = 0;
    wait for 10 ns;
    data_in <= '0';
    
    -- From: #10;
    wait for 10 ns;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  -- Matches Verilog testbench timing: checks at 15, 25, 35, 45, 55, 65, 75, 85, 95, 115ns
  verify_process : process
    variable case_num : integer := 0;
  begin
    -- From Verilog: #5; (initial offset)
    wait for 5 ns;
    
    -- 10 checks with 10ns spacing (except last has 20ns)
    for i in 0 to 8 loop
      wait for 10 ns;  -- Checks at 15, 25, 35, 45, 55, 65, 75, 85, 95ns
      
      if not sim_done then
        if data_out /= expected_results(case_num) then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_data_out <= stats1.errors_data_out + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_data_out = 1 then
            stats1.errortime_data_out <= now;
          end if;
        end if;
        
        case_num := case_num + 1;
        case_num_shared <= case_num;
      end if;
    end loop;
    
    -- Last check with 20ns spacing
    wait for 20 ns;  -- Check at 115ns
    if not sim_done then
      if data_out /= expected_results(case_num) then
        stats1.errors <= stats1.errors + 1;
        stats1.errors_data_out <= stats1.errors_data_out + 1;
        
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        if stats1.errors_data_out = 1 then
          stats1.errortime_data_out <= now;
        end if;
      end if;
      
      case_num := case_num + 1;
      case_num_shared <= case_num;
    end if;
    
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_data_out > 0 then
      write(l, string'("Hint: Output 'data_out' has "));
      write(l, stats1.errors_data_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_data_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'data_out' has no mismatches."));
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
    
    -- ========== Console Output (mirror file) ==========
    info("========================================");
    
    if stats1.errors_data_out > 0 then
      info("Hint: Output 'data_out' has " & integer'image(stats1.errors_data_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_data_out / 1 ps) & ".");
    else
      info("Hint: Output 'data_out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(expected_cases) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(expected_cases) & " samples");
    
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