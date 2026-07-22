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
  constant PERIOD : time := 10 ns;  -- From: always #5 clk_tb = ~clk_tb (5ns half-period)
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal freq : std_logic_vector(7 downto 0) := "00000100";  -- From: reg [8:0] freq_tb = 8'b0000100;
  signal wave_out : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_wave_out    : integer;
    errortime_wave_out : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_wave_out    => 0,
    errortime_wave_out => 0 ps,
    clocks             => 0
  );
  
  -- For tracking consecutive ones
  signal ones_count : integer := 0;
  
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
  dut1 : entity work.square_wave
    port map (
      clk      => clk,
      freq     => freq,
      wave_out => wave_out
    );
  
  -- ========== Stimulus Generation (from Verilog initial blocks) ==========
  stimulus_process : process
    variable ones_count_var : integer := 0;
  begin
    sim_done <= false;
    
    -- From: repeat (200) begin ... #5; end
    -- Simulate for 200 iterations with 5ns delay each = 1000ns
    for i in 0 to 199 loop
      -- Check for consecutive ones (error detection)
      if wave_out = '1' then
        ones_count_var := ones_count_var + 1;
        ones_count <= ones_count_var;
        
        -- From: if (ones_count > 8) begin ... error = 1; $finish; end
        if ones_count_var > 8 then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_wave_out <= stats1.errors_wave_out + 1;
          if stats1.errortime = 0 ps then
            stats1.errortime <= now;
            stats1.errortime_wave_out <= now;
          end if;
          info("Error: More than 8 consecutive ones detected at time " & integer'image(now / 1 ps));
          exit;  -- Stop the loop
        end if;
      else
        ones_count_var := 0;
        ones_count <= 0;
      end if;
      
      -- From: #5;
      wait for 5 ns;
    end loop;
    
    -- From: $finish;
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
    wait for 1500 ns;  -- Longer than simulation time
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_wave_out > 0 then
      write(l, string'("Hint: Output 'wave_out' has "));
      write(l, stats1.errors_wave_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_wave_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'wave_out' has no mismatches."));
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
    
    if stats1.errors_wave_out > 0 then
      info("Hint: Output 'wave_out' has " & integer'image(stats1.errors_wave_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_wave_out / 1 ps) & ".");
    else
      info("Hint: Output 'wave_out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    -- From: if (error == 0) begin $display("=========== Your Design Passed ==========="); end
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;