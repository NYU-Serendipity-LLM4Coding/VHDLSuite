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
  constant CLK_A_PERIOD : time := 10 ns;  -- 5ns half-period
  constant CLK_B_PERIOD : time := 20 ns;  -- 10ns half-period
  
  -- ========== Signals ==========
  signal clk_a : std_logic := '0';
  signal clk_b : std_logic := '0';
  signal arstn : std_logic := '0';
  signal brstn : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal data_in : std_logic_vector(3 downto 0) := (others => '0');
  signal data_en : std_logic := '0';
  signal dataout : std_logic_vector(3 downto 0);
  
  -- ========== Expected Values ==========
  type result_array_t is array (0 to 2) of unsigned(3 downto 0);
  constant expected_results : result_array_t := (
    0 => to_unsigned(4, 4),
    1 => to_unsigned(7, 4),
    2 => to_unsigned(9, 4)
  );
  
  constant expected_cases : integer := 3;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_dataout     : integer;
    errortime_dataout  : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_dataout     => 0,
    errortime_dataout  => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  
  -- Check points for verification
  signal check_point : std_logic := '0';
  
begin

  -- ========== Clock Generation ==========
  clk_a_process : process
  begin
    clk_a <= '0';
    wait for CLK_A_PERIOD / 2;
    clk_a <= '1';
    wait for CLK_A_PERIOD / 2;
  end process;
  
  clk_b_process : process
  begin
    clk_b <= '0';
    wait for CLK_B_PERIOD / 2;
    clk_b <= '1';
    wait for CLK_B_PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.synchronizer
    port map (
      clk_a    => clk_a,
      clk_b    => clk_b,
      arstn    => arstn,
      brstn    => brstn,
      data_in  => data_in,
      data_en  => data_en,
      dataout  => dataout
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial state
    arstn <= '0';
    brstn <= '0';
    data_en <= '0';
    data_in <= (others => '0');
    
    -- #20 arstn = 1; Release reset
    wait for 20 ns;
    arstn <= '1';
    
    -- #5 brstn = 1;
    wait for 5 ns;
    brstn <= '1';
    
    -- #50 data_in = 4; Set data_in to 4
    wait for 50 ns;
    data_in <= std_logic_vector(to_unsigned(4, 4));
    
    -- #10 data_en = 1; Enable data
    wait for 10 ns;
    data_en <= '1';
    
    -- #100; Wait for data to propagate
    wait for 100 ns;
    check_point <= '1';
    wait for 1 ns;
    check_point <= '0';
    
    -- #10 data_en = 0; Disable data
    wait for 10 ns;
    data_en <= '0';
    
    -- #100;
    wait for 100 ns;
    
    -- #50 data_in = 7; Set data_in to 7
    wait for 50 ns;
    data_in <= std_logic_vector(to_unsigned(7, 4));
    
    -- #10 data_en = 1; Enable data
    wait for 10 ns;
    data_en <= '1';
    
    -- #80;
    wait for 80 ns;
    check_point <= '1';
    wait for 1 ns;
    check_point <= '0';
    
    -- #10 data_en = 0; Disable data
    wait for 10 ns;
    data_en <= '0';
    
    -- #100;
    wait for 100 ns;
    
    -- #50;
    wait for 50 ns;
    
    -- #20 arstn = 0; Assert reset
    wait for 20 ns;
    arstn <= '0';
    
    -- #100;
    wait for 100 ns;
    
    -- #20 arstn = 1; Release reset
    wait for 20 ns;
    arstn <= '1';
    
    -- #50 data_in = 9; Set data_in to 9
    wait for 50 ns;
    data_in <= std_logic_vector(to_unsigned(9, 4));
    
    -- #10 data_en = 1; Enable data
    wait for 10 ns;
    data_en <= '1';
    
    -- #100;
    wait for 100 ns;
    check_point <= '1';
    wait for 1 ns;
    check_point <= '0';
    
    -- #10 data_en = 0; Disable data
    wait for 10 ns;
    data_en <= '0';
    
    -- #100;
    wait for 100 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(check_point)
    variable case_num : integer := 0;
  begin
    if rising_edge(check_point) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check dataout against expected value at check points
        if unsigned(dataout) /= expected_results(case_num) then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_dataout <= stats1.errors_dataout + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_dataout = 1 then
            stats1.errortime_dataout <= now;
          end if;
        end if;
        
        case_num := case_num + 1;
        case_num_shared <= case_num;
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
    
    -- ========== Write to summary.txt ==========
    
    if stats1.errors_dataout > 0 then
      write(l, string'("Hint: Output 'dataout' has "));
      write(l, stats1.errors_dataout);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_dataout / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'dataout' has no mismatches."));
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
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_dataout > 0 then
      info("Hint: Output 'dataout' has " & integer'image(stats1.errors_dataout) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_dataout / 1 ps) & ".");
    else
      info("Hint: Output 'dataout' has no mismatches.");
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
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(stats1.errors) & 
           " /" & integer'image(expected_cases) & " failures===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;