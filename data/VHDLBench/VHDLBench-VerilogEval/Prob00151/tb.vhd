-- (2) Testbench (tb entity)
-- Main Testbench for Timer FSM
-- Verifies shift_ena, counting, and done outputs
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
  signal reset          : std_logic := '0';
  signal data           : std_logic := '0';
  signal done_counting  : std_logic := '0';
  signal ack            : std_logic := '0';
  signal shift_ena_ref  : std_logic;
  signal shift_ena_dut  : std_logic;
  signal counting_ref   : std_logic;
  signal counting_dut   : std_logic;
  signal done_ref       : std_logic;
  signal done_dut       : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors                : integer;
    errortime             : time;
    errors_shift_ena      : integer;
    errortime_shift_ena   : time;
    errors_counting       : integer;
    errortime_counting    : time;
    errors_done           : integer;
    errortime_done        : time;
    clocks                : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors              => 0,
    errortime           => 0 ps,
    errors_shift_ena    => 0,
    errortime_shift_ena => 0 ps,
    errors_counting     => 0,
    errortime_counting  => 0 ps,
    errors_done         => 0,
    errortime_done      => 0 ps,
    clocks              => 0
  );
  
  -- Verification signals
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
  -- Helper function for X matching (X in ref matches anything)
  function match_with_x(ref, dut : std_logic) return boolean is
  begin
    if ref = 'X' or ref = 'U' or ref = 'Z' or ref = 'W' or ref = '-' then
      return true;  -- X in reference matches anything
    else
      return ref = dut;
    end if;
  end function;
  
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
      clk           => clk,
      reset         => reset,
      data          => data,
      done_counting => done_counting,
      ack           => ack,
      tb_match      => tb_match,
      sim_done      => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk           => clk,
      reset         => reset,
      data          => data,
      done_counting => done_counting,
      ack           => ack,
      shift_ena     => shift_ena_ref,
      counting      => counting_ref,
      done          => done_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk           => clk,
      reset         => reset,
      data          => data,
      done_counting => done_counting,
      ack           => ack,
      shift_ena     => shift_ena_dut,
      counting      => counting_dut,
      done          => done_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic with X handling
  -----------------------------------------------------------------------------
  tb_match <= match_with_x(shift_ena_ref, shift_ena_dut) and
              match_with_x(counting_ref, counting_dut) and
              match_with_x(done_ref, done_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
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
        
        -- Check shift_ena
        if not match_with_x(shift_ena_ref, shift_ena_dut) then
          if stats1.errors_shift_ena = 0 then
            stats1.errortime_shift_ena <= now;
          end if;
          stats1.errors_shift_ena <= stats1.errors_shift_ena + 1;
        end if;
        
        -- Check counting
        if not match_with_x(counting_ref, counting_dut) then
          if stats1.errors_counting = 0 then
            stats1.errortime_counting <= now;
          end if;
          stats1.errors_counting <= stats1.errors_counting + 1;
        end if;
        
        -- Check done
        if not match_with_x(done_ref, done_dut) then
          if stats1.errors_done = 0 then
            stats1.errortime_done <= now;
          end if;
          stats1.errors_done <= stats1.errors_done + 1;
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
    
    -- Write summary for shift_ena
    if stats1.errors_shift_ena > 0 then
      write(l, string'("Hint: Output 'shift_ena' has "));
      write(l, stats1.errors_shift_ena);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_shift_ena / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'shift_ena' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for counting
    if stats1.errors_counting > 0 then
      write(l, string'("Hint: Output 'counting' has "));
      write(l, stats1.errors_counting);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_counting / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'counting' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for done
    if stats1.errors_done > 0 then
      write(l, string'("Hint: Output 'done' has "));
      write(l, stats1.errors_done);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_done / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'done' has no mismatches."));
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
    if stats1.errors_shift_ena > 0 then
      info("Hint: Output 'shift_ena' has " & integer'image(stats1.errors_shift_ena) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_shift_ena / 1 ps) & " ps.");
    else
      info("Hint: Output 'shift_ena' has no mismatches.");
    end if;
    
    if stats1.errors_counting > 0 then
      info("Hint: Output 'counting' has " & integer'image(stats1.errors_counting) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_counting / 1 ps) & " ps.");
    else
      info("Hint: Output 'counting' has no mismatches.");
    end if;
    
    if stats1.errors_done > 0 then
      info("Hint: Output 'done' has " & integer'image(stats1.errors_done) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_done / 1 ps) & " ps.");
    else
      info("Hint: Output 'done' has no mismatches.");
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