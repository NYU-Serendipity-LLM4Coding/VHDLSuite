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
  signal rst : std_logic := '1';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(31 downto 0) := (others => '0');
  signal b : std_logic_vector(31 downto 0) := (others => '0');
  signal z : std_logic_vector(31 downto 0);
  
  -- ========== Expected Values ==========
  constant expected_result : std_logic_vector(31 downto 0) := "00111101101110000101000111101100";
  
  constant expected_cases : integer := 1;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_z           : integer;
    errortime_z        : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_z           => 0,
    errortime_z        => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    while not sim_done loop
      clk <= '0';
      wait for PERIOD / 2;
      clk <= '1';
      wait for PERIOD / 2;
    end loop;
    wait;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.float_multi
    port map (
      clk => clk,
      rst => rst,
      a   => a,
      b   => b,
      z   => z
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial reset
    rst <= '1';
    wait for 13 ns;
    rst <= '0';
    
    -- Wait initial 3ns
    wait for 3 ns;
    
    -- First iteration (2 cycles of 80ns each)
    wait for 80 ns;
    a <= "00111110100110011001100110011010";
    b <= "00111110100110011001100110011010";
    
    wait for 80 ns;
    a <= "00111110100110011001100110011010";
    b <= "00111110100110011001100110011010";
    
    -- Final wait before checking
    wait for 80 ns;
    
    -- Small delay before ending
    wait for 10 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
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
    variable local_errors : integer := 0;
  begin
    -- Wait for simulation to complete
    wait until sim_done;
    wait for 10 ns;
    
    -- Check the result
    if z /= expected_result then
      local_errors := 1;
    end if;
    
    -- Update stats
    stats1.errors <= local_errors;
    if local_errors > 0 then
      stats1.errors_z <= 1;
    end if;
    
    case_num_shared <= 1;
    
    -- ========== Write to summary.txt ==========
    
    if local_errors > 0 then
      write(l, string'("Hint: Output 'z' has "));
      write(l, local_errors);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, now / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'z' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, local_errors);
    write(l, string'(" out of "));
    write(l, stats1.clocks);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, local_errors);
    write(l, string'(" in "));
    write(l, stats1.clocks);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if local_errors > 0 then
      info("Hint: Output 'z' has " & integer'image(local_errors) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(now / 1 ps) & ".");
    else
      info("Hint: Output 'z' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(local_errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(local_errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    if local_errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(local_errors) & "/20 failures ===========");
      check_failed("Test failed: " & integer'image(local_errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;