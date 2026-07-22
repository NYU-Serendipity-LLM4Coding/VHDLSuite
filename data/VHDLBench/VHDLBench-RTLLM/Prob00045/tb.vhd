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
  signal rst : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal fetch : std_logic_vector(1 downto 0) := "00";
  signal data : std_logic_vector(7 downto 0) := x"00";
  signal ins : std_logic_vector(2 downto 0);
  signal ad1 : std_logic_vector(4 downto 0);
  signal ad2 : std_logic_vector(7 downto 0);
  
  -- ========== Expected Values ==========
  type test_case_t is record
    expected_ins : std_logic_vector(2 downto 0);
    expected_ad1 : std_logic_vector(4 downto 0);
    expected_ad2 : std_logic_vector(7 downto 0);
    check_time : time;
  end record;
  
  type test_array_t is array (0 to 0) of test_case_t;
  constant expected_tests : test_array_t := (
    0 => (expected_ins => "010",
          expected_ad1 => "11100",
          expected_ad2 => "00000000",
          check_time => 130 ns)
  );
  
  constant expected_cases : integer := 1;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_ins         : integer;
    errortime_ins      : time;
    errors_ad1         : integer;
    errortime_ad1      : time;
    errors_ad2         : integer;
    errortime_ad2      : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_ins         => 0,
    errortime_ins      => 0 ps,
    errors_ad1         => 0,
    errortime_ad1      => 0 ps,
    errors_ad2         => 0,
    errortime_ad2      => 0 ps,
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
  dut1 : entity work.instr_reg
    port map (
      clk   => clk,
      rst   => rst,
      fetch => fetch,
      data  => data,
      ins   => ins,
      ad1   => ad1,
      ad2   => ad2
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initialize Inputs
    clk <= '0';
    rst <= '0';
    fetch <= "00";
    data <= x"00";
    
    -- Wait 100 ns for initialization
    wait for 100 ns;
    
    -- De-assert reset
    rst <= '1';
    wait for 10 ns;
    
    -- Perform fetch operation 1 from register
    fetch <= "01";
    wait for 5 ns;
    data <= "01011100";
    wait for 20 ns;
    
    -- Additional test cases can be added here
    
    -- Finish simulation
    wait for 100 ns;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
    variable has_error : boolean := false;
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check at specific time point (130 ns)
        if now = 130 ns and case_num < expected_cases then
          has_error := false;
          
          -- Check ins
          if ins /= expected_tests(case_num).expected_ins then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_ins <= stats1.errors_ins + 1;
            has_error := true;
            
            if stats1.errors_ins = 1 then
              stats1.errortime_ins <= now;
            end if;
          end if;
          
          -- Check ad1
          if ad1 /= expected_tests(case_num).expected_ad1 then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_ad1 <= stats1.errors_ad1 + 1;
            has_error := true;
            
            if stats1.errors_ad1 = 1 then
              stats1.errortime_ad1 <= now;
            end if;
          end if;
          
          -- Check ad2
          if ad2 /= expected_tests(case_num).expected_ad2 then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_ad2 <= stats1.errors_ad2 + 1;
            has_error := true;
            
            if stats1.errors_ad2 = 1 then
              stats1.errortime_ad2 <= now;
            end if;
          end if;
          
          -- Record first error time overall
          if has_error and stats1.errortime = 0 ps then
            stats1.errortime <= now;
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_ins > 0 then
      write(l, string'("Hint: Output 'ins' has "));
      write(l, stats1.errors_ins);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_ins / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'ins' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_ad1 > 0 then
      write(l, string'("Hint: Output 'ad1' has "));
      write(l, stats1.errors_ad1);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_ad1 / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'ad1' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_ad2 > 0 then
      write(l, string'("Hint: Output 'ad2' has "));
      write(l, stats1.errors_ad2);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_ad2 / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'ad2' has no mismatches."));
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
    
    if stats1.errors_ins > 0 then
      info("Hint: Output 'ins' has " & integer'image(stats1.errors_ins) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_ins / 1 ps) & ".");
    else
      info("Hint: Output 'ins' has no mismatches.");
    end if;
    
    if stats1.errors_ad1 > 0 then
      info("Hint: Output 'ad1' has " & integer'image(stats1.errors_ad1) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_ad1 / 1 ps) & ".");
    else
      info("Hint: Output 'ad1' has no mismatches.");
    end if;
    
    if stats1.errors_ad2 > 0 then
      info("Hint: Output 'ad2' has " & integer'image(stats1.errors_ad2) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_ad2 / 1 ps) & ".");
    else
      info("Hint: Output 'ad2' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
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