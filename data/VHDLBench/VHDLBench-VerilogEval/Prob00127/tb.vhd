-- (2) Testbench (tb entity)
-- Main Testbench for Lemmings FSM
-- Verifies walk_left and walk_right outputs
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
  signal areset         : std_logic := '0';
  signal bump_left      : std_logic := '0';
  signal bump_right     : std_logic := '0';
  signal walk_left_ref  : std_logic;
  signal walk_left_dut  : std_logic;
  signal walk_right_ref : std_logic;
  signal walk_right_dut : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors                : integer;
    errortime             : time;
    errors_walk_left      : integer;
    errortime_walk_left   : time;
    errors_walk_right     : integer;
    errortime_walk_right  : time;
    clocks                : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors               => 0,
    errortime            => 0 ps,
    errors_walk_left     => 0,
    errortime_walk_left  => 0 ps,
    errors_walk_right    => 0,
    errortime_walk_right => 0 ps,
    clocks               => 0
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
      clk             => clk,
      areset          => areset,
      bump_left       => bump_left,
      bump_right      => bump_right,
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
      clk        => clk,
      areset     => areset,
      bump_left  => bump_left,
      bump_right => bump_right,
      walk_left  => walk_left_ref,
      walk_right => walk_right_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk        => clk,
      areset     => areset,
      bump_left  => bump_left,
      bump_right => bump_right,
      walk_left  => walk_left_dut,
      walk_right => walk_right_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (walk_left_ref = walk_left_dut) and 
              (walk_right_ref = walk_right_dut);
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
        
        -- Check walk_left
        if walk_left_ref /= walk_left_dut then
          if stats1.errors_walk_left = 0 then
            stats1.errortime_walk_left <= now;
          end if;
          stats1.errors_walk_left <= stats1.errors_walk_left + 1;
        end if;
        
        -- Check walk_right
        if walk_right_ref /= walk_right_dut then
          if stats1.errors_walk_right = 0 then
            stats1.errortime_walk_right <= now;
          end if;
          stats1.errors_walk_right <= stats1.errors_walk_right + 1;
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
    
    -- Write summary for walk_left
    if stats1.errors_walk_left > 0 then
      write(l, string'("Hint: Output 'walk_left' has "));
      write(l, stats1.errors_walk_left);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_walk_left / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'walk_left' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for walk_right
    if stats1.errors_walk_right > 0 then
      write(l, string'("Hint: Output 'walk_right' has "));
      write(l, stats1.errors_walk_right);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_walk_right / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'walk_right' has no mismatches."));
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
    if stats1.errors_walk_left > 0 then
      info("Hint: Output 'walk_left' has " & integer'image(stats1.errors_walk_left) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_walk_left / 1 ps) & " ps.");
    else
      info("Hint: Output 'walk_left' has no mismatches.");
    end if;
    
    if stats1.errors_walk_right > 0 then
      info("Hint: Output 'walk_right' has " & integer'image(stats1.errors_walk_right) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_walk_right / 1 ps) & " ps.");
    else
      info("Hint: Output 'walk_right' has no mismatches.");
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