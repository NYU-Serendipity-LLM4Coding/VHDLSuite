-- (2) Testbench (tb entity)
-- Main Testbench for One-Hot State Machine Next-State Logic
-- Verifies Y2 and Y4 outputs
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
  signal y      : std_logic_vector(6 downto 1) := (others => '0');
  signal w      : std_logic := '0';
  signal Y2_ref : std_logic;
  signal Y2_dut : std_logic;
  signal Y4_ref : std_logic;
  signal Y4_dut : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_Y2      : integer;
    errortime_Y2   : time;
    errors_Y4      : integer;
    errortime_Y4   : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors       => 0,
    errortime    => 0 ps,
    errors_Y2    => 0,
    errortime_Y2 => 0 ps,
    errors_Y4    => 0,
    errortime_Y4 => 0 ps,
    clocks       => 0
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
      clk      => clk,
      y        => y,
      w        => w,
      tb_match => tb_match,
      sim_done => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      y  => y,
      w  => w,
      Y2 => Y2_ref,
      Y4 => Y4_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      y  => y,
      w  => w,
      Y2 => Y2_dut,
      Y4 => Y4_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ Y2_ref, Y4_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match    <= (Y2_ref = Y2_dut) and (Y4_ref = Y4_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
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
        
        -- Check Y2
        if Y2_ref /= Y2_dut then
          if stats1.errors_Y2 = 0 then
            stats1.errortime_Y2 <= now;
          end if;
          stats1.errors_Y2 <= stats1.errors_Y2 + 1;
        end if;
        
        -- Check Y4
        if Y4_ref /= Y4_dut then
          if stats1.errors_Y4 = 0 then
            stats1.errortime_Y4 <= now;
          end if;
          stats1.errors_Y4 <= stats1.errors_Y4 + 1;
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
    
    -- Write summary for Y2
    if stats1.errors_Y2 > 0 then
      write(l, string'("Hint: Output 'Y2' has "));
      write(l, stats1.errors_Y2);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Y2 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Y2' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for Y4
    if stats1.errors_Y4 > 0 then
      write(l, string'("Hint: Output 'Y4' has "));
      write(l, stats1.errors_Y4);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Y4 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Y4' has no mismatches."));
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
    if stats1.errors_Y2 > 0 then
      info("Hint: Output 'Y2' has " & integer'image(stats1.errors_Y2) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_Y2 / 1 ps) & " ps.");
    else
      info("Hint: Output 'Y2' has no mismatches.");
    end if;
    
    if stats1.errors_Y4 > 0 then
      info("Hint: Output 'Y4' has " & integer'image(stats1.errors_Y4) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_Y4 / 1 ps) & " ps.");
    else
      info("Hint: Output 'Y4' has no mismatches.");
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