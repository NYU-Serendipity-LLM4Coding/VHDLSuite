-- (2) Testbench (tb entity)
-- Main Testbench for 100-bit Neighbor Comparison
-- Verifies out_both, out_any, and out_different outputs
-- Corresponds to Verilog module: tb
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

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
  signal signal_in       : std_logic_vector(99 downto 0) := (others => '0');
  signal out_both_ref    : std_logic_vector(98 downto 0);
  signal out_both_dut    : std_logic_vector(98 downto 0);
  signal out_any_ref     : std_logic_vector(99 downto 1);
  signal out_any_dut     : std_logic_vector(99 downto 1);
  signal out_different_ref : std_logic_vector(99 downto 0);
  signal out_different_dut : std_logic_vector(99 downto 0);
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type (matches Verilog struct stats)
  type stats_t is record
    errors                  : integer;
    errortime               : time;
    errors_out_both         : integer;
    errortime_out_both      : time;
    errors_out_any          : integer;
    errortime_out_any       : time;
    errors_out_different    : integer;
    errortime_out_different : time;
    clocks                  : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors                  => 0,
    errortime               => 0 ps,
    errors_out_both         => 0,
    errortime_out_both      => 0 ps,
    errors_out_any          => 0,
    errortime_out_any       => 0 ps,
    errors_out_different    => 0,
    errortime_out_different => 0 ps,
    clocks                  => 0
  );
  
  -- Verification signals
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
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
      clk       => clk,
      tb_match  => tb_match,
      signal_in => signal_in,
      sim_done  => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      signal_in     => signal_in,
      out_both      => out_both_ref,
      out_any       => out_any_ref,
      out_different => out_different_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      signal_in     => signal_in,
      out_both      => out_both_dut,
      out_any       => out_any_dut,
      out_different => out_different_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ out_both_ref, out_any_ref, out_different_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (out_both_ref = out_both_dut) and 
              (out_any_ref = out_any_dut) and
              (out_different_ref = out_different_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -- CRITICAL: Only count when not sim_done to prevent spurious mismatches
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
        
        -- Check out_both
        if out_both_ref /= out_both_dut then
          if stats1.errors_out_both = 0 then
            stats1.errortime_out_both <= now;
          end if;
          stats1.errors_out_both <= stats1.errors_out_both + 1;
        end if;
        
        -- Check out_any
        if out_any_ref /= out_any_dut then
          if stats1.errors_out_any = 0 then
            stats1.errortime_out_any <= now;
          end if;
          stats1.errors_out_any <= stats1.errors_out_any + 1;
        end if;
        
        -- Check out_different
        if out_different_ref /= out_different_dut then
          if stats1.errors_out_different = 0 then
            stats1.errortime_out_different <= now;
          end if;
          stats1.errors_out_different <= stats1.errors_out_different + 1;
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
  -- Matches Verilog: final begin ... end
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 1000000 ps;
    
    -- Write summary for out_both
    if stats1.errors_out_both > 0 then
      write(l, string'("Hint: Output 'out_both' has "));
      write(l, stats1.errors_out_both);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_both / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_both' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out_any
    if stats1.errors_out_any > 0 then
      write(l, string'("Hint: Output 'out_any' has "));
      write(l, stats1.errors_out_any);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_any / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_any' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out_different
    if stats1.errors_out_different > 0 then
      write(l, string'("Hint: Output 'out_different' has "));
      write(l, stats1.errors_out_different);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_different / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_different' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Total summary
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
    if stats1.errors_out_both > 0 then
      info("Hint: Output 'out_both' has " & integer'image(stats1.errors_out_both) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_both / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_both' has no mismatches.");
    end if;
    
    if stats1.errors_out_any > 0 then
      info("Hint: Output 'out_any' has " & integer'image(stats1.errors_out_any) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_any / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_any' has no mismatches.");
    end if;
    
    if stats1.errors_out_different > 0 then
      info("Hint: Output 'out_different' has " & integer'image(stats1.errors_out_different) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_different / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_different' has no mismatches.");
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