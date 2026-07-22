-- (2) Testbench (tb entity)
-- Main Testbench for HDLC Framing FSM
-- Verifies disc, flag, and err outputs
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
  
  -- DUT signals (renamed to avoid VHDL keywords)
  signal reset      : std_logic := '0';
  signal signal_in  : std_logic := '0';
  signal disc_ref   : std_logic;
  signal disc_dut   : std_logic;
  signal flag_ref   : std_logic;
  signal flag_dut   : std_logic;
  signal err_ref    : std_logic;
  signal err_dut    : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type (extended for three outputs)
  type stats_t is record
    errors            : integer;
    errortime         : time;
    errors_disc       : integer;
    errortime_disc    : time;
    errors_flag       : integer;
    errortime_flag    : time;
    errors_err        : integer;
    errortime_err     : time;
    clocks            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors         => 0,
    errortime      => 0 ps,
    errors_disc    => 0,
    errortime_disc => 0 ps,
    errors_flag    => 0,
    errortime_flag => 0 ps,
    errors_err     => 0,
    errortime_err  => 0 ps,
    clocks         => 0
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
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk       => clk,
      reset     => reset,
      signal_in => signal_in,
      sim_done  => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk   => clk,
      reset => reset,
      signal_in => signal_in,
      disc  => disc_ref,
      flag  => flag_ref,
      err   => err_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk   => clk,
      reset => reset,
      signal_in => signal_in,
      disc  => disc_dut,
      flag  => flag_dut,
      err   => err_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ disc_ref, flag_ref, err_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (disc_ref = disc_dut) and 
              (flag_ref = flag_dut) and 
              (err_ref = err_dut);
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
        
        -- Check disc output
        if disc_ref /= disc_dut then
          if stats1.errors_disc = 0 then
            stats1.errortime_disc <= now;
          end if;
          stats1.errors_disc <= stats1.errors_disc + 1;
        end if;
        
        -- Check flag output
        if flag_ref /= flag_dut then
          if stats1.errors_flag = 0 then
            stats1.errortime_flag <= now;
          end if;
          stats1.errors_flag <= stats1.errors_flag + 1;
        end if;
        
        -- Check err output
        if err_ref /= err_dut then
          if stats1.errors_err = 0 then
            stats1.errortime_err <= now;
          end if;
          stats1.errors_err <= stats1.errors_err + 1;
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
    if stats1.errors_disc > 0 then
      write(l, string'("Hint: Output 'disc' has "));
      write(l, stats1.errors_disc);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_disc / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'disc' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_flag > 0 then
      write(l, string'("Hint: Output 'flag' has "));
      write(l, stats1.errors_flag);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_flag / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'flag' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_err > 0 then
      write(l, string'("Hint: Output 'err' has "));
      write(l, stats1.errors_err);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_err / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'err' has no mismatches."));
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
    if stats1.errors_disc > 0 then
      info("Hint: Output 'disc' has " & integer'image(stats1.errors_disc) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_disc / 1 ps) & " ps.");
    else
      info("Hint: Output 'disc' has no mismatches.");
    end if;
    
    if stats1.errors_flag > 0 then
      info("Hint: Output 'flag' has " & integer'image(stats1.errors_flag) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_flag / 1 ps) & " ps.");
    else
      info("Hint: Output 'flag' has no mismatches.");
    end if;
    
    if stats1.errors_err > 0 then
      info("Hint: Output 'err' has " & integer'image(stats1.errors_err) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_err / 1 ps) & " ps.");
    else
      info("Hint: Output 'err' has no mismatches.");
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