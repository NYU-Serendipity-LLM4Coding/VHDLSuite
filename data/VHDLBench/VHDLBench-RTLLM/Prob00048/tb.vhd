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
  constant DELAY : time := 10 ns;
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal addr : std_logic_vector(7 downto 0) := (others => '0');
  signal dout : std_logic_vector(15 downto 0);
  
  -- ========== Expected Values ==========
  type result_array_t is array (0 to 3) of std_logic_vector(15 downto 0);
  constant expected_results : result_array_t := (
    0 => x"A0A0",
    1 => x"B1B1",
    2 => x"C2C2",
    3 => x"D3D3"
  );
  
  constant expected_cases : integer := 4;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_dout        : integer;
    errortime_dout     : time;
    samples            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_dout        => 0,
    errortime_dout     => 0 ps,
    samples            => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.ROM
    port map (
      addr => addr,
      dout => dout
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Test reading data from different memory locations
    
    -- addr_tb = 8'h00;
    addr <= x"00";
    wait for DELAY;
    
    -- addr_tb = 8'h01;
    addr <= x"01";
    wait for DELAY;
    
    -- addr_tb = 8'h02;
    addr <= x"02";
    wait for DELAY;
    
    -- addr_tb = 8'h03;
    addr <= x"03";
    wait for DELAY;
    
    -- End simulation
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable case_num : integer := 0;
  begin
    -- Check each test case at 10ns, 20ns, 30ns, 40ns
    for i in 0 to 3 loop
      wait for DELAY;
      
      if not sim_done then
        stats1.samples <= stats1.samples + 1;
        
        -- Check dout against expected value
        if dout /= expected_results(case_num) then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_dout <= stats1.errors_dout + 1;
          
          -- Record first error time (check when errors = 0, before increment)
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_dout = 0 then
            stats1.errortime_dout <= now;
          end if;
        end if;
        
        -- Increment case counter
        case_num := case_num + 1;
        case_num_shared <= case_num;
      end if;
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- Wait for simulation done signal
    wait until sim_done;
    wait for DELAY * 2;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_dout > 0 then
      write(l, string'("Hint: Output 'dout' has "));
      write(l, stats1.errors_dout);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_dout / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'dout' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.samples);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.samples);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output (mirror file) ==========
    info("========================================");
    
    if stats1.errors_dout > 0 then
      info("Hint: Output 'dout' has " & integer'image(stats1.errors_dout) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_dout / 1 ps) & ".");
    else
      info("Hint: Output 'dout' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.samples) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.samples) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("=========== Your Design Passed ===========");
    else
      info("Test completed with " & integer'image(stats1.errors) & " errors.");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;