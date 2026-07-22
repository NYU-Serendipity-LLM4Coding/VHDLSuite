-- (1) Testbench with integrated stimulus (tb entity)
-- VUnit framework + stimulus generation + verification against expected values
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  -- ========== Constants ==========
  constant CLK_PERIOD : time := 10 ns;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal d : std_logic_vector(3 downto 0) := (others => '0');
  signal valid_out : std_logic;
  signal dout : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_dout        : integer;
    errortime_dout     : time;
    errors_valid_out   : integer;
    errortime_valid_out: time;
    clocks             : integer;
    failed_cases       : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_dout        => 0,
    errortime_dout     => 0 ps,
    errors_valid_out   => 0,
    errortime_valid_out=> 0 ps,
    clocks             => 0,
    failed_cases       => 0
  );
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.parallel2serial
    port map (
      clk       => clk,
      rst_n     => rst_n,
      d         => d,
      valid_out => valid_out,
      dout      => dout
    );
  
  -- ========== Stimulus and Verification ==========
  stimulus_process : process
    variable seed1, seed2 : integer := 999;
    variable rand_val : real;
    variable rand_int : integer;
    variable test_d : std_logic_vector(3 downto 0);
    variable case_error : integer;
  begin
    sim_done <= false;
    
    -- Loop through 100 test cases
    for i in 0 to NUM_TESTS-1 loop
      case_error := 0;
      
      -- Initialize inputs
      rst_n <= '0';
      d <= "0000";
      
      wait for CLK_PERIOD;
      rst_n <= '1';
      wait for CLK_PERIOD;
      
      -- Generate random 4-bit value
      uniform(seed1, seed2, rand_val);
      rand_int := integer(rand_val * 16.0);
      test_d := std_logic_vector(to_unsigned(rand_int, 4));
      d <= test_d;
      
      -- Wait for valid_out to be 1
      while valid_out = '0' loop
        wait until rising_edge(clk);
      end loop;
      
      -- Check bit 3 (MSB) with valid_out=1
      if dout /= test_d(3) or valid_out /= '1' then
        case_error := case_error + 1;
        stats1.errors <= stats1.errors + 1;
        if dout /= test_d(3) then
          stats1.errors_dout <= stats1.errors_dout + 1;
          if stats1.errors_dout = 1 then
            stats1.errortime_dout <= now;
          end if;
        end if;
        if valid_out /= '1' then
          stats1.errors_valid_out <= stats1.errors_valid_out + 1;
          if stats1.errors_valid_out = 1 then
            stats1.errortime_valid_out <= now;
          end if;
        end if;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
      end if;
      
      wait for CLK_PERIOD;
      
      -- Check bit 2 with valid_out=0
      if dout /= test_d(2) or valid_out /= '0' then
        case_error := case_error + 1;
        stats1.errors <= stats1.errors + 1;
        if dout /= test_d(2) then
          stats1.errors_dout <= stats1.errors_dout + 1;
          if stats1.errors_dout = 1 then
            stats1.errortime_dout <= now;
          end if;
        end if;
        if valid_out /= '0' then
          stats1.errors_valid_out <= stats1.errors_valid_out + 1;
          if stats1.errors_valid_out = 1 then
            stats1.errortime_valid_out <= now;
          end if;
        end if;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
      end if;
      
      wait for CLK_PERIOD;
      
      -- Check bit 1 with valid_out=0
      if dout /= test_d(1) or valid_out /= '0' then
        case_error := case_error + 1;
        stats1.errors <= stats1.errors + 1;
        if dout /= test_d(1) then
          stats1.errors_dout <= stats1.errors_dout + 1;
          if stats1.errors_dout = 1 then
            stats1.errortime_dout <= now;
          end if;
        end if;
        if valid_out /= '0' then
          stats1.errors_valid_out <= stats1.errors_valid_out + 1;
          if stats1.errors_valid_out = 1 then
            stats1.errortime_valid_out <= now;
          end if;
        end if;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
      end if;
      
      wait for CLK_PERIOD;
      
      -- Check bit 0 (LSB) with valid_out=0
      if dout /= test_d(0) or valid_out /= '0' then
        case_error := case_error + 1;
        stats1.errors <= stats1.errors + 1;
        if dout /= test_d(0) then
          stats1.errors_dout <= stats1.errors_dout + 1;
          if stats1.errors_dout = 1 then
            stats1.errortime_dout <= now;
          end if;
        end if;
        if valid_out /= '0' then
          stats1.errors_valid_out <= stats1.errors_valid_out + 1;
          if stats1.errors_valid_out = 1 then
            stats1.errortime_valid_out <= now;
          end if;
        end if;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
      end if;
      
      wait for CLK_PERIOD;
      
      -- Check that valid_out=1 again
      if valid_out /= '1' then
        case_error := case_error + 1;
        stats1.errors <= stats1.errors + 1;
        stats1.errors_valid_out <= stats1.errors_valid_out + 1;
        if stats1.errors_valid_out = 1 then
          stats1.errortime_valid_out <= now;
        end if;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
      end if;
      
      wait for CLK_PERIOD;
      
      -- Update failed cases count
      if case_error > 0 then
        stats1.failed_cases <= stats1.failed_cases + 1;
      end if;
      
    end loop;
    
    sim_done <= true;
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
    wait until sim_done;
    wait for CLK_PERIOD * 2;
    
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
    
    if stats1.errors_valid_out > 0 then
      write(l, string'("Hint: Output 'valid_out' has "));
      write(l, stats1.errors_valid_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_valid_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'valid_out' has no mismatches."));
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
    
    if stats1.errors_dout > 0 then
      info("Hint: Output 'dout' has " & integer'image(stats1.errors_dout) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_dout / 1 ps) & ".");
    else
      info("Hint: Output 'dout' has no mismatches.");
    end if;
    
    if stats1.errors_valid_out > 0 then
      info("Hint: Output 'valid_out' has " & integer'image(stats1.errors_valid_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_valid_out / 1 ps) & ".");
    else
      info("Hint: Output 'valid_out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.failed_cases = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(stats1.failed_cases) & 
           " /100 failures===========");
      check_failed("Test failed: " & integer'image(stats1.failed_cases) & " test cases failed");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;