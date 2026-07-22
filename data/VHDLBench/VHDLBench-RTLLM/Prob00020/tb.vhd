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
  constant CLK_PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal valid_count : std_logic := '0';
  signal out_signal : std_logic_vector(3 downto 0);
  signal sim_done : boolean := false;
  
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
  
  -- Test phase control
  type test_phase_t is (PHASE_RESET, PHASE_VALID_CHECK, PHASE_COUNTER, PHASE_PAUSE, PHASE_DONE);
  signal test_phase : test_phase_t := PHASE_RESET;
  signal phase_cycle_count : integer := 0;
  signal counter_i : integer := 0;
  
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
  dut1 : entity work.counter_12
    port map (
      rst_n       => rst_n,
      clk         => clk,
      valid_count => valid_count,
      out_port    => out_signal
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial state
    rst_n <= '0';
    valid_count <= '0';
    
    -- From: #20 rst_n = 1;
    wait for 20 ns;
    rst_n <= '1';
    test_phase <= PHASE_VALID_CHECK;
    
    -- testcase1: validation of valid_count (15 cycles)
    -- From: repeat(15) begin ... #10; end
    wait for 150 ns;
    
    -- From: #100 valid_count = 1;
    wait for 100 ns;
    valid_count <= '1';
    test_phase <= PHASE_COUNTER;
    
    -- testcase2: counter (11 cycles)
    -- From: repeat(11) begin ... #10; end
    wait for 110 ns;
    
    -- testcase3: the count is paused if valid_count is invalid
    -- From: valid_count = 0;
    valid_count <= '0';
    test_phase <= PHASE_PAUSE;
    
    -- From: repeat(5) begin ... #10; end
    wait for 50 ns;
    
    test_phase <= PHASE_DONE;
    
    -- From: $finish;
    wait for 20 ns;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable expected_value : integer := 0;
    variable cycle_in_phase : integer := 0;
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        case test_phase is
          when PHASE_RESET =>
            -- No checking during reset
            null;
            
          when PHASE_VALID_CHECK =>
            -- testcase1: validation of valid_count
            -- From: error = (out == 0) ?error:error+1;
            if unsigned(out_signal) /= 0 then
              stats1.errors <= stats1.errors + 1;
              stats1.errors_out <= stats1.errors_out + 1;
              if stats1.errors = 1 then
                stats1.errortime <= now;
              end if;
              if stats1.errors_out = 1 then
                stats1.errortime_out <= now;
              end if;
            end if;
            
          when PHASE_COUNTER =>
            -- testcase2: counter
            -- From: error = (out == i) ?error:error+1; i = i+1;
            if unsigned(out_signal) /= to_unsigned(counter_i, 4) then
              stats1.errors <= stats1.errors + 1;
              stats1.errors_out <= stats1.errors_out + 1;
              if stats1.errors = 1 then
                stats1.errortime <= now;
              end if;
              if stats1.errors_out = 1 then
                stats1.errortime_out <= now;
              end if;
            end if;
            counter_i <= counter_i + 1;
            
          when PHASE_PAUSE =>
            -- testcase3: the count is paused if valid_count is invalid
            -- From: error = (out == 11) ?error:error+1;
            if unsigned(out_signal) /= 11 then
              stats1.errors <= stats1.errors + 1;
              stats1.errors_out <= stats1.errors_out + 1;
              if stats1.errors = 1 then
                stats1.errortime <= now;
              end if;
              if stats1.errors_out = 1 then
                stats1.errortime_out <= now;
              end if;
            end if;
            
          when PHASE_DONE =>
            null;
        end case;
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
    if stats1.errors_out > 0 then
      write(l, string'("Hint: Output 'out_port' has "));
      write(l, stats1.errors_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_port' has no mismatches."));
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
    
    if stats1.errors_out > 0 then
      info("Hint: Output 'out_port' has " & integer'image(stats1.errors_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_out / 1 ps) & ".");
    else
      info("Hint: Output 'out_port' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    -- From: if (error == 0) $display("...Passed...");
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Failed===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;