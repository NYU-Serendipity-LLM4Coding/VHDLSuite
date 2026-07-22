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
  constant PERIOD : time := 10 ns;
  
  signal clk : std_logic := '1';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  signal clk_div : std_logic;
  
  -- Corrected expected values based on Verilog testbench logic
  -- The Verilog checks BEFORE updating expected_value each iteration
  type expected_array_t is array (0 to 19) of std_logic;
  constant expected_results : expected_array_t := (
    0 => '1',   -- i=0: expect 1 (initial value)
    1 => '1',   -- i=1: expect 1
    2 => '1',   -- i=2: expect 1 (updated AFTER check)
    3 => '0',   -- i=3: expect 0
    4 => '0',   -- i=4: expect 0
    5 => '0',   -- i=5: expect 0
    6 => '0',   -- i=6: expect 0 (updated AFTER check)
    7 => '1',   -- i=7: expect 1
    8 => '1',   -- i=8: expect 1
    9 => '1',   -- i=9: expect 1 (updated AFTER check)
    10 => '0',  -- i=10: expect 0
    11 => '0',  -- i=11: expect 0
    12 => '0',  -- i=12: expect 0
    13 => '0',  -- i=13: expect 0 (updated AFTER check)
    14 => '1',  -- i=14: expect 1
    15 => '1',  -- i=15: expect 1
    16 => '1',  -- i=16: expect 1 (updated AFTER check)
    17 => '0',  -- i=17: expect 0
    18 => '0',  -- i=18: expect 0
    19 => '0'   -- i=19: expect 0
  );
  
  constant expected_cases : integer := 20;
  
  signal error_count : integer := 0;
  signal first_error_time : time := 0 ps;
  signal sample_count : integer := 0;
  signal case_num_shared : integer := 0;
  
begin

  clk_process : process
  begin
    if not sim_done then
      clk <= '1';
      wait for PERIOD / 2;
      clk <= '0';
      wait for PERIOD / 2;
    else
      wait;
    end if;
  end process;
  
  dut1 : entity work.freq_divbyfrac
    port map (
      clk     => clk,
      rst_n   => rst_n,
      clk_div => clk_div
    );
  
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: #10 rst_n = 1;
    wait for 10 ns;
    rst_n <= '1';
    
    -- From: #120;
    wait for 120 ns;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  verify_process : process
    variable local_error_count : integer := 0;
    variable local_first_error_time : time := 0 ps;
  begin
    -- From: #15;
    wait for 15 ns;
    
    -- From: for (i = 0; i < 20; i = i + 1)
    for i in 0 to 19 loop
      if not sim_done then
        sample_count <= i + 1;
        
        -- From: if (clk_div !== expected_value)
        if clk_div /= expected_results(i) then
          local_error_count := local_error_count + 1;
          
          if local_error_count = 1 then
            local_first_error_time := now;
          end if;
        end if;
        
        case_num_shared <= i + 1;
      end if;
      
      -- From: #5;
      wait for 5 ns;
    end loop;
    
    error_count <= local_error_count;
    first_error_time <= local_first_error_time;
    wait;
  end process;
  
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  report_process : process
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    wait until sim_done;
    wait for PERIOD * 2;
    
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- Per-output error statistics
    if error_count > 0 then
      write(l, string'("Hint: Output 'clk_div' has "));
      write(l, error_count);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, first_error_time / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'clk_div' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, error_count);
    write(l, string'(" out of "));
    write(l, sample_count);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, error_count);
    write(l, string'(" in "));
    write(l, sample_count);
    write(l, string'(" samples"));
    writeline(f, l);
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if error_count > 0 then
      info("Hint: Output 'clk_div' has " & integer'image(error_count) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(first_error_time / 1 ps) & ".");
    else
      info("Hint: Output 'clk_div' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(error_count) & " out of " & 
         integer'image(sample_count) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(error_count) & 
         " in " & integer'image(sample_count) & " samples");
    
    info("========================================");
    
    -- From: if (error == 0) $display("=========== Your Design Passed ===========");
    if error_count = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(error_count) & 
           "/20 failures ===========");
      check_failed("Test failed: " & integer'image(error_count) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;