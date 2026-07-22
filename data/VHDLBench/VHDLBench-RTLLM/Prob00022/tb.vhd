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
  constant PERIOD : time := 10 ns;  -- From: #5 clk <= ~clk; (half period = 5ns)
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal reset : std_logic := '1';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal out_sig : std_logic_vector(7 downto 0);
  
  -- ========== Expected Values (from Verilog data array) ==========
  type data_array_t is array (0 to 9) of std_logic_vector(7 downto 0);
  constant expected_data : data_array_t := (
    0 => "00000001",
    1 => "00000001",
    2 => "00000010",
    3 => "00000100",
    4 => "00001000",
    5 => "00010000",
    6 => "00100000",
    7 => "01000000",
    8 => "10000000",
    9 => "00000001"
  );
  
  constant expected_cases : integer := 10;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_out         : integer;
    errortime_out      : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_out         => 0,
    errortime_out      => 0 ps,
    clocks             => 0
  );
  
  -- For sharing case count
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
  dut1 : entity work.ring_counter
    port map (
      clk   => clk,
      reset => reset,
      o     => out_sig
    );
  
  -- ========== Stimulus Generation (from Verilog initial blocks) ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: initial begin clk = 0; reset = 1; i=0;
    reset <= '1';
    
    -- From: #10 reset = 0;
    wait for PERIOD * 1;
    reset <= '0';
    
    -- Wait for all test cases to complete
    wait for PERIOD * 10;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check out against expected value
        if case_num < expected_cases then
          if out_sig /= expected_data(case_num) then
            -- Increment error counters
            stats1.errors <= stats1.errors + 1;
            stats1.errors_out <= stats1.errors_out + 1;
            
            -- Record first error time
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_out = 1 then
              stats1.errortime_out <= now;
            end if;
          end if;
          
          -- Increment case counter
          case_num := case_num + 1;
          case_num_shared <= case_num;  -- Update signal for report_process
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
    if stats1.errors_out > 0 then
      write(l, string'("Hint: Output 'out' has "));
      write(l, stats1.errors_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out' has no mismatches."));
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
    
    if stats1.errors_out > 0 then
      info("Hint: Output 'out' has " & integer'image(stats1.errors_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_out / 1 ps) & ".");
    else
      info("Hint: Output 'out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("=========== Your Design Passed ===========");
    else
      info("Test failed");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;