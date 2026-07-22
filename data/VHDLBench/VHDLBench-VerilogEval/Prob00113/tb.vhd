-- (2) Testbench (tb entity)
-- Main Testbench for Karnaugh Map Function
-- Instantiates stimulus_gen, RefModule, and TopModule
-- Performs verification and generates summary.txt
-- Corresponds to Verilog module: tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity tb;

architecture sim of tb is
  
  -- Clock
  signal clk : std_logic := '0';
  constant clk_period : time := 10 ps;
  
  -- DUT signals
  signal x       : std_logic_vector(4 downto 1) := "0000";
  signal f_ref   : std_logic;
  signal f_dut   : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type (matches Verilog struct stats)
  type stats_t is record
    errors      : integer;
    errortime   : time;
    errors_f    : integer;
    errortime_f : time;
    clocks      : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors      => 0,
    errortime   => 0 ps,
    errors_f    => 0,
    errortime_f => 0 ps,
    clocks      => 0
  );
  
  -- Verification signals
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation
  -- Matches Verilog: initial forever #5 clk = ~clk;
  -----------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;
  
  -----------------------------------------------------------------------------
  -- Stimulus generator instantiation
  -- Matches Verilog: stimulus_gen stim1 (.clk, .*, .x);
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk      => clk,
      x        => x,
      sim_done => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -- Matches Verilog: RefModule good1 (.x, .f(f_ref));
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      x => x,
      f => f_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -- Matches Verilog: TopModule top_module1 (.x, .f(f_dut));
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      x => x,
      f => f_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ f_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match    <= (f_ref = f_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -- CRITICAL: Only count when not sim_done to prevent extra mismatches
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check overall match
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Check specific output
        -- Matches Verilog: if (f_ref !== (f_ref ^ f_dut ^ f_ref))
        if f_ref /= f_dut then
          if stats1.errors_f = 0 then
            stats1.errortime_f <= now;
          end if;
          stats1.errors_f <= stats1.errors_f + 1;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- VUnit runner process
  -----------------------------------------------------------------------------
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;  -- Wait for report process to cleanup
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -- Matches Verilog: final begin ... end
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for timeout (matches Verilog timeout: #1000000)
    wait for 1000000 ps;
    
    -- Generate summary.txt (matches Verilog final block)
    if stats1.errors_f > 0 then
      write(l, string'("Hint: Output 'f' has "));
      write(l, stats1.errors_f);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_f / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'f' has no mismatches."));
      writeline(f, l);
    end if;
    
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
    
    file_close(f);
    
    -- Console output (matches Verilog $display)
    info("========================================");
    if stats1.errors_f > 0 then
      info("Hint: Output 'f' has " & integer'image(stats1.errors_f) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_f / 1 ps) & " ps.");
    else
      info("Hint: Output 'f' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
    -- Pass/Fail determination
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & 
                   " mismatches in " & integer'image(stats1.clocks) & " samples");
    else
      info("PASS: All " & integer'image(stats1.clocks) & " samples matched!");
    end if;
    
    -- Cleanup and stop
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;