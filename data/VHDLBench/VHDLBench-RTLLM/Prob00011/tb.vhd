-- VHDL Testbench for multi_16bit (VUnit Framework)
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
  constant CLK_PERIOD : time := 10 ns;  -- From: #5 clk = ~clk (period = 10ns)
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '1';
  signal start : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal ain : std_logic_vector(15 downto 0) := (others => '0');
  signal bin : std_logic_vector(15 downto 0) := (others => '0');
  signal yout : std_logic_vector(31 downto 0);
  signal done : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_yout        : integer;
    errortime_yout     : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_yout        => 0,
    errortime_yout     => 0 ps,
    clocks             => 0
  );
  
  -- For sharing between processes (use signals instead of shared variables)
  signal fail_count_shared : integer := 0;
  signal test_count_shared : integer := 0;
  
  -- LFSR for pseudo-random number generation
  signal lfsr : std_logic_vector(31 downto 0) := x"12345678";
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    while not sim_done loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.multi_16bit
    port map (
      clk    => clk,
      rst_n  => rst_n,
      start  => start,
      ain    => ain,
      bin    => bin,
      yout   => yout,
      done   => done
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1, seed2 : positive := 1;
    variable rand_val : real;
    variable ain_val, bin_val : integer;
    variable expected_product : unsigned(31 downto 0);
    variable timeout_counter : integer;
    variable local_fail_count : integer := 0;
    variable local_test_count : integer := 0;
  begin
    sim_done <= false;
    
    -- Initialize
    rst_n <= '1';
    start <= '0';
    
    -- Perform 100 test iterations
    for i in 0 to 99 loop
      -- Reset phase
      wait for 1000 ns;  -- #100 in Verilog (100 time units * 10ns)
      rst_n <= '1';
      wait for 500 ns;   -- #50
      
      -- Generate random inputs (simple LFSR-based)
      lfsr <= lfsr(30 downto 0) & (lfsr(31) xor lfsr(21) xor lfsr(1) xor lfsr(0));
      ain_val := to_integer(unsigned(lfsr(15 downto 0)));
      ain <= std_logic_vector(to_unsigned(ain_val, 16));
      
      lfsr <= lfsr(30 downto 0) & (lfsr(31) xor lfsr(21) xor lfsr(1) xor lfsr(0));
      bin_val := to_integer(unsigned(lfsr(15 downto 0)));
      bin <= std_logic_vector(to_unsigned(bin_val, 16));
      
      wait for 500 ns;   -- #50
      
      -- Start operation
      start <= '1';
      
      -- Wait for done signal (with timeout)
      timeout_counter := 0;
      while done /= '1' and timeout_counter < 1000 loop
        wait for 100 ns;  -- #10
        timeout_counter := timeout_counter + 1;
      end loop;
      
      -- Calculate expected product
      expected_product := to_unsigned(ain_val, 16) * to_unsigned(bin_val, 16);
      
      -- Check result
      if done = '1' then
        if unsigned(yout) /= expected_product then
          local_fail_count := local_fail_count + 1;
          stats1.errors <= stats1.errors + 1;
          stats1.errors_yout <= stats1.errors_yout + 1;
          
          -- Record first error time
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_yout = 1 then
            stats1.errortime_yout <= now;
          end if;
        end if;
      end if;
      
      local_test_count := local_test_count + 1;
      
      -- Stop operation
      start <= '0';
      rst_n <= '0';
      wait for 1000 ns;  -- #100
    end loop;
    
    -- Update shared signals
    fail_count_shared <= local_fail_count;
    test_count_shared <= local_test_count;
    
    -- Signal end of simulation
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Process ==========
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
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for simulation to complete
    wait for 60000 ns;  -- Timeout at 50000 + margin
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_yout > 0 then
      write(l, string'("Hint: Output 'yout' has "));
      write(l, stats1.errors_yout);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_yout / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'yout' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, test_count_shared);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, test_count_shared);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_yout > 0 then
      info("Hint: Output 'yout' has " & integer'image(stats1.errors_yout) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_yout / 1 ps) & ".");
    else
      info("Hint: Output 'yout' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(test_count_shared) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(test_count_shared) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if fail_count_shared = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(fail_count_shared) & 
           " / 100 failures===========");
      check_failed("Test failed: " & integer'image(fail_count_shared) & " failures detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;