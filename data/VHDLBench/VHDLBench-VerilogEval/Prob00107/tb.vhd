-- (2) Testbench (tb entity)
-- Main Testbench for Moore State Machine
-- Verifies two-state FSM with synchronous reset
-- Corresponds to Verilog module: tb
-- Variable name changes: 'in' -> 'signal_in', 'reset' -> 'signal_reset', 'out' -> 'signal_out'

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
  signal signal_in     : std_logic := '0';
  signal signal_reset  : std_logic := '1';
  signal signal_out    : std_logic;
  signal out_ref       : std_logic;
  
  -- Control signals
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Verification
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
  -- Statistics
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_out     : integer;
    errortime_out  : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_out    => 0,
    errortime_out => 0 ps,
    clocks        => 0
  );
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation
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
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk             => clk,
      signal_in       => signal_in,
      signal_reset    => signal_reset,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      tb_match        => tb_match,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk          => clk,
      signal_in    => signal_in,
      signal_reset => signal_reset,
      signal_out   => out_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk          => clk,
      signal_in    => signal_in,
      signal_reset => signal_reset,
      signal_out   => signal_out
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match    <= (out_ref = signal_out);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- CRITICAL: Only count mismatches when sim_done is false
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
        if out_ref /= signal_out then
          if stats1.errors_out = 0 then
            stats1.errortime_out <= now;
          end if;
          stats1.errors_out <= stats1.errors_out + 1;
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
    wait;
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 1000000 ps;
    
    -- Generate summary.txt
    if stats1.errors_out > 0 then
      write(l, string'("Hint: Output 'out' has "));
      write(l, stats1.errors_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out' has no mismatches."));
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
    
    -- Console output
    info("========================================");
    if stats1.errors_out > 0 then
      info("Hint: Output 'out' has " & integer'image(stats1.errors_out) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out / 1 ps) & " ps.");
    else
      info("Hint: Output 'out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & 
                   " mismatches in " & integer'image(stats1.clocks) & " samples");
    else
      info("PASS: All " & integer'image(stats1.clocks) & " samples matched!");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;