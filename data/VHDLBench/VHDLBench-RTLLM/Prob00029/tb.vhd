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
  signal out_tb : std_logic_vector(3 downto 0);
  
  -- ========== Expected Values ==========
  constant expected_value : std_logic_vector(3 downto 0) := "1101";
  
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
  dut1 : entity work.LFSR
    port map (
      lfsr_out => out_tb,
      clk      => clk,
      rst      => rst
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From Verilog: rst_tb = 1;
    rst <= '1';
    
    -- From Verilog: #15;
    wait for 15 ns;
    
    -- From Verilog: rst_tb = 0;
    rst <= '0';
    
    -- From Verilog: #200; but check should happen after edge 20 (t=205ns)
    -- Edge 20 is at t=205ns where out=1101
    -- Edge 21 is at t=215ns where out=1011
    -- To match Verilog behavior (check before edge 21), wait 190ns
    wait for 190 ns;  -- t=15+190=205ns (edge 20)
    
    -- From Verilog: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
      end if;
    end if;
  end process;
  
  -- ========== Final Check Process ==========
  final_check_process : process
  begin
    wait until sim_done;
    wait for 1 ns;  -- t=206ns, after edge 20 but before edge 21
    
    -- From Verilog: if (out_tb == 4'b1101)
    if out_tb /= expected_value then
      stats1.errors <= 1;
      stats1.errors_out <= 1;
      stats1.errortime <= now;
      stats1.errortime_out <= now;
    end if;
    
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- CRITICAL: Wait for sim_done, NOT fixed time
    wait until sim_done;
    wait for PERIOD * 2;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
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
    write(l, string'(" out of 1 samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in 1 samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_out > 0 then
      info("Hint: Output 'out' has " & integer'image(stats1.errors_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_out / 1 ps) & ".");
    else
      info("Hint: Output 'out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of 1 samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & " in 1 samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Failed ===========");
      check_failed("Test failed: output mismatch detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;