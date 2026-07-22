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
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal input_data : std_logic_vector(7 downto 0) := (others => '0');
  signal ctrl : std_logic_vector(2 downto 0) := (others => '0');
  signal output_data : std_logic_vector(7 downto 0);
  
  -- ========== Expected Values ==========
  type result_array_t is array (0 to 3) of unsigned(7 downto 0);
  constant expected_results : result_array_t := (
    0 => to_unsigned(8, 8),    -- 128 >> 4 = 8
    1 => to_unsigned(32, 8),   -- 128 >> 2 = 32
    2 => to_unsigned(64, 8),   -- 128 >> 1 = 64
    3 => to_unsigned(1, 8)     -- 255 >> 7 = 1
  );
  
  constant expected_cases : integer := 4;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_output      : integer;
    errortime_output   : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_output      => 0,
    errortime_output   => 0 ps,
    clocks             => 0
  );
  
  -- For sharing case count
  signal case_num_shared : integer := 0;
  signal check_enable : std_logic := '0';
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.barrel_shifter
    port map (
      input_data  => input_data,
      ctrl        => ctrl,
      output_data => output_data
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    check_enable <= '0';
    
    -- Initial: in=0, ctrl=0 (no shift)
    input_data <= std_logic_vector(to_unsigned(0, 8));
    ctrl <= "000";
    wait for PERIOD * 1;
    
    -- #10 in=128, ctrl=4 (shift 4 bit)
    input_data <= std_logic_vector(to_unsigned(128, 8));
    ctrl <= "100";
    wait for PERIOD * 1;
    
    -- #10 check error (out==8)
    check_enable <= '1';
    wait for PERIOD * 1;
    check_enable <= '0';
    
    -- #10 in=128, ctrl=2 (shift 2 bit)
    input_data <= std_logic_vector(to_unsigned(128, 8));
    ctrl <= "010";
    wait for PERIOD * 1;
    
    -- #10 check error (out==32)
    check_enable <= '1';
    wait for PERIOD * 1;
    check_enable <= '0';
    
    -- #10 in=128, ctrl=1 (shift 1 bit)
    input_data <= std_logic_vector(to_unsigned(128, 8));
    ctrl <= "001";
    wait for PERIOD * 1;
    
    -- #10 check error (out==64)
    check_enable <= '1';
    wait for PERIOD * 1;
    check_enable <= '0';
    
    -- #10 in=255, ctrl=7 (shift 7 bit)
    input_data <= std_logic_vector(to_unsigned(255, 8));
    ctrl <= "111";
    wait for PERIOD * 1;
    
    -- #10 check error (out==1)
    check_enable <= '1';
    wait for PERIOD * 1;
    check_enable <= '0';
    
    wait for PERIOD * 1;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable case_num : integer := 0;
  begin
    wait until check_enable = '1';
    
    while not sim_done loop
      if check_enable = '1' then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check output_data against expected value
        if unsigned(output_data) /= expected_results(case_num) then
          -- Increment error counters
          stats1.errors <= stats1.errors + 1;
          stats1.errors_output <= stats1.errors_output + 1;
          
          -- Record first error time
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_output = 1 then
            stats1.errortime_output <= now;
          end if;
        end if;
        
        -- Increment case counter
        case_num := case_num + 1;
        case_num_shared <= case_num;
        
        wait until check_enable = '0';
      end if;
      
      wait until check_enable = '1' or sim_done;
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_output > 0 then
      write(l, string'("Hint: Output 'output_data' has "));
      write(l, stats1.errors_output);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_output / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'output_data' has no mismatches."));
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
    
    if stats1.errors_output > 0 then
      info("Hint: Output 'output_data' has " & integer'image(stats1.errors_output) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_output / 1 ps) & ".");
    else
      info("Hint: Output 'output_data' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
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