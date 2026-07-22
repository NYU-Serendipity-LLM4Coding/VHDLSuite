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
  constant PERIOD : time := 10 ns;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(7 downto 0) := (others => '0');
  signal b : std_logic_vector(7 downto 0) := (others => '0');
  signal cin : std_logic := '0';
  signal sum : std_logic_vector(7 downto 0);
  signal cout : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors : integer;
    errortime : time;
    clocks : integer;
    test_count : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors => 0,
    errortime => 0 ps,
    clocks => 0,
    test_count => 0
  );
  
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
  dut1 : entity work.adder_8bit
    port map (
      a => a,
      b => b,
      cin => cin,
      sum => sum,
      cout => cout
    );
  
  -- ========== Stimulus Generation (Randomized) ==========
  stimulus_process : process
    variable seed1, seed2 : integer := 999;
    variable rand_val : real;
    variable rand_int : integer;
  begin
    sim_done <= false;
    
    -- Run 100 random test cases
    for i in 0 to NUM_TESTS - 1 loop
      -- Generate random a (8-bit)
      uniform(seed1, seed2, rand_val);
      rand_int := integer(rand_val * 256.0);
      a <= std_logic_vector(to_unsigned(rand_int mod 256, 8));
      
      -- Generate random b (8-bit)
      uniform(seed1, seed2, rand_val);
      rand_int := integer(rand_val * 256.0);
      b <= std_logic_vector(to_unsigned(rand_int mod 256, 8));
      
      -- Generate random cin (1-bit)
      uniform(seed1, seed2, rand_val);
      if rand_val > 0.5 then
        cin <= '1';
      else
        cin <= '0';
      end if;
      
      -- Wait for propagation delay
      wait for PERIOD;
    end loop;
    
    -- Extra wait for final check
    wait for PERIOD;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable expected_result : unsigned(8 downto 0);
    variable actual_result : unsigned(8 downto 0);
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Skip first clock (inputs not yet valid)
        if stats1.clocks > 0 then
          -- Calculate expected result: a + b + cin (9-bit result)
          expected_result := resize(unsigned(a), 9) + resize(unsigned(b), 9) + ("" & cin);
          
          -- Get actual result from DUT
          actual_result := unsigned(cout & sum);
          
          -- Compare
          if actual_result /= expected_result then
            stats1.errors <= stats1.errors + 1;
            
            -- Record first error time
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
          end if;
          
          stats1.test_count <= stats1.test_count + 1;
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
    if stats1.errors > 0 then
      write(l, string'("Hint: Output 'sum/cout' has "));
      write(l, stats1.errors);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'sum/cout' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.test_count);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.test_count);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors > 0 then
      info("Hint: Output 'sum/cout' has " & integer'image(stats1.errors) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime / 1 ps) & ".");
    else
      info("Hint: Output 'sum/cout' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.test_count) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.test_count) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(stats1.errors) & 
           " /" & integer'image(NUM_TESTS) & " failures===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;