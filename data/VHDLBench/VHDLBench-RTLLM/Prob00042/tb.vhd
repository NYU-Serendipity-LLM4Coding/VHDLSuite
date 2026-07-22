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
  signal clk : std_logic := '1';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal valid_in : std_logic := '0';
  signal data_in : std_logic_vector(7 downto 0) := (others => '0');
  signal valid_out : std_logic;
  signal data_out : std_logic_vector(15 downto 0);
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    clocks             => 0
  );
  
  signal error_count : integer := 0;
  constant total_tests : integer := 3;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '1';
    wait for PERIOD / 2;
    clk <= '0';
    wait for PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.width_8to16
    port map (
      clk       => clk,
      rst_n     => rst_n,
      valid_in  => valid_in,
      data_in   => data_in,
      valid_out => valid_out,
      data_out  => data_out
    );
  
  -- ========== Stimulus and Verification Combined ==========
  stimulus_process : process
    variable local_error : integer := 0;
  begin
    sim_done <= false;
    
    -- Initial: rst=0;valid_in=0;
    rst_n <= '0';
    valid_in <= '0';
    
    -- #10 rst=1;valid_in=1;data_in=8'b10100000;
    wait for 10 ns;
    rst_n <= '1';
    valid_in <= '1';
    data_in <= "10100000";
    
    -- Check 1: error = valid_out ==0 ? error : error+1;
    wait for 0 ns;  -- Sample immediately
    if valid_out /= '0' then
      local_error := local_error + 1;
    end if;
    
    -- #10 data_in=8'b10100001;
    wait for 10 ns;
    data_in <= "10100001";
    
    -- #10 data_in=8'b10110000;
    wait for 10 ns;
    data_in <= "10110000";
    
    -- Check 2: error = (data_out == 16'b1010000010100001 && valid_out ==1 )? error : error+1;
    wait for 0 ns;  -- Sample immediately
    if data_out /= "1010000010100001" or valid_out /= '1' then
      local_error := local_error + 1;
    end if;
    
    -- #10 valid_in=0;
    wait for 10 ns;
    valid_in <= '0';
    
    -- #20 valid_in=1;data_in=8'b10110001;
    wait for 20 ns;
    valid_in <= '1';
    data_in <= "10110001";
    
    -- #10 valid_in=0;
    wait for 10 ns;
    valid_in <= '0';
    
    -- Check 3: error = (data_out == 16'b1011000010110001 && valid_out ==1 )? error : error+1;
    wait for 0 ns;  -- Sample immediately
    if data_out /= "1011000010110001" or valid_out /= '1' then
      local_error := local_error + 1;
    end if;
    
    -- #30
    wait for 30 ns;
    
    -- Update error count
    error_count <= local_error;
    stats1.errors <= local_error;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Clock Counter ==========
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
  begin
    -- Wait for simulation to complete
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if error_count > 0 then
      write(l, string'("Hint: Outputs have mismatches."));
      writeline(f, l);
    else
      write(l, string'("Hint: All outputs match expected values."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, error_count);
    write(l, string'(" out of "));
    write(l, total_tests);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, error_count);
    write(l, string'(" in "));
    write(l, total_tests);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if error_count > 0 then
      info("Hint: Outputs have mismatches.");
    else
      info("Hint: All outputs match expected values.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(error_count) & " out of " & 
         integer'image(total_tests) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(error_count) & 
         " in " & integer'image(total_tests) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if error_count = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(error_count) & 
           " / " & integer'image(total_tests) & " failures===========");
      check_failed("Test failed: " & integer'image(error_count) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;