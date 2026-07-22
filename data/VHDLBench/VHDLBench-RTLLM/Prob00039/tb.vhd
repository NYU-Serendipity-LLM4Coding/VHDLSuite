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
  signal din_serial : std_logic := '0';
  signal din_valid : std_logic := '0';
  signal dout_valid : std_logic;
  signal dout_parallel : std_logic_vector(7 downto 0);
  
  -- ========== Expected Values ==========
  type result_array_t is array (0 to 1) of std_logic_vector(7 downto 0);
  constant expected_results : result_array_t := (
    0 => "11110000",  -- First expected output
    1 => "11000011"   -- Second expected output
  );
  
  constant expected_cases : integer := 2;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors                  : integer;
    errortime               : time;
    errors_dout_parallel    : integer;
    errortime_dout_parallel : time;
    errors_dout_valid       : integer;
    errortime_dout_valid    : time;
    clocks                  : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors                  => 0,
    errortime               => 0 ps,
    errors_dout_parallel    => 0,
    errortime_dout_parallel => 0 ps,
    errors_dout_valid       => 0,
    errortime_dout_valid    => 0 ps,
    clocks                  => 0
  );
  
  signal case_num_shared : integer := 0;
  signal test_phase : integer := 0;  -- Track which test phase we're in
  
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
  dut1 : entity work.serial2parallel
    port map (
      clk           => clk,
      rst_n         => rst_n,
      din_serial    => din_serial,
      din_valid     => din_valid,
      dout_parallel => dout_parallel,
      dout_valid    => dout_valid
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial state
    clk <= '0';
    rst_n <= '0';
    
    -- #12 rst_n <= 1'b1;
    wait for 12 ns;
    rst_n <= '1';
    din_valid <= '1';
    
    -- First sequence: 11110000
    -- din_serial <= 1'b1; #10;
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 10 ns;
    din_serial <= '1';
    test_phase <= 1;  -- Check dout_valid should be 0
    
    wait for 10 ns;
    din_serial <= '0';
    
    wait for 10 ns;
    din_serial <= '0';
    
    wait for 10 ns;
    din_serial <= '0';
    
    wait for 10 ns;
    din_serial <= '0';
    
    -- Wait for dout_valid
    test_phase <= 2;  -- Check first output
    while dout_valid = '0' loop
      wait for 5 ns;
    end loop;
    
    -- din_valid <= 1'b0; #30;
    din_valid <= '0';
    wait for 30 ns;
    
    -- din_valid <= 1'b1;
    din_valid <= '1';
    
    -- Second sequence: 11000011
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 10 ns;
    din_serial <= '0';
    
    wait for 10 ns;
    din_serial <= '0';
    test_phase <= 3;  -- Check dout_valid should be 0
    
    wait for 10 ns;
    din_serial <= '0';
    
    wait for 10 ns;
    din_serial <= '0';
    
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 10 ns;
    din_serial <= '1';
    
    wait for 20 ns;
    din_valid <= '0';
    
    -- Wait for dout_valid
    test_phase <= 4;  -- Check second output
    while dout_valid = '0' loop
      wait for 5 ns;
    end loop;
    
    wait for 10 ns;
    test_phase <= 5;  -- Check dout_valid should be 0
    
    wait for 10 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Process ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check dout_valid at specific test phases
        if test_phase = 1 or test_phase = 3 then
          -- Should be 0 after 4 bits
          if dout_valid /= '0' then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_dout_valid <= stats1.errors_dout_valid + 1;
            if stats1.errors_dout_valid = 1 then
              stats1.errortime_dout_valid <= now;
            end if;
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
          end if;
        elsif test_phase = 5 then
          -- Should be 0 after output
          if dout_valid /= '0' then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_dout_valid <= stats1.errors_dout_valid + 1;
            if stats1.errors_dout_valid = 1 then
              stats1.errortime_dout_valid <= now;
            end if;
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
          end if;
        end if;
        
        -- Check dout_parallel when dout_valid is 1
        if dout_valid = '1' and case_num < expected_cases then
          if dout_parallel /= expected_results(case_num) then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_dout_parallel <= stats1.errors_dout_parallel + 1;
            if stats1.errors_dout_parallel = 1 then
              stats1.errortime_dout_parallel <= now;
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
    
    -- Per-output error statistics
    if stats1.errors_dout_parallel > 0 then
      write(l, string'("Hint: Output 'dout_parallel' has "));
      write(l, stats1.errors_dout_parallel);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_dout_parallel / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'dout_parallel' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_dout_valid > 0 then
      write(l, string'("Hint: Output 'dout_valid' has "));
      write(l, stats1.errors_dout_valid);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_dout_valid / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'dout_valid' has no mismatches."));
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
    
    -- Console Output
    info("========================================");
    
    if stats1.errors_dout_parallel > 0 then
      info("Hint: Output 'dout_parallel' has " & integer'image(stats1.errors_dout_parallel) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_dout_parallel / 1 ps) & ".");
    else
      info("Hint: Output 'dout_parallel' has no mismatches.");
    end if;
    
    if stats1.errors_dout_valid > 0 then
      info("Hint: Output 'dout_valid' has " & integer'image(stats1.errors_dout_valid) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_dout_valid / 1 ps) & ".");
    else
      info("Hint: Output 'dout_valid' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;