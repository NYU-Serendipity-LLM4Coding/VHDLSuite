-- (2) Testbench (tb entity)
-- Main Testbench for 12-hour BCD Clock
-- Verifies pm, hh, mm, ss outputs against reference
-- CRITICAL: Uses sim_done flag to prevent spurious mismatches after stimulus ends
-- CRITICAL: report_process waits for sim_done, NOT fixed timeout
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
  signal reset  : std_logic := '0';
  signal ena    : std_logic := '0';
  signal pm_ref : std_logic;
  signal pm_dut : std_logic;
  signal hh_ref : std_logic_vector(7 downto 0);
  signal hh_dut : std_logic_vector(7 downto 0);
  signal mm_ref : std_logic_vector(7 downto 0);
  signal mm_dut : std_logic_vector(7 downto 0);
  signal ss_ref : std_logic_vector(7 downto 0);
  signal ss_dut : std_logic_vector(7 downto 0);
  
  -- Control signals
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors            : integer;
    errortime         : time;
    errors_pm         : integer;
    errortime_pm      : time;
    errors_hh         : integer;
    errortime_hh      : time;
    errors_mm         : integer;
    errortime_mm      : time;
    errors_ss         : integer;
    errortime_ss      : time;
    clocks            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors       => 0,
    errortime    => 0 ps,
    errors_pm    => 0,
    errortime_pm => 0 ps,
    errors_hh    => 0,
    errortime_hh => 0 ps,
    errors_mm    => 0,
    errortime_mm => 0 ps,
    errors_ss    => 0,
    errortime_ss => 0 ps,
    clocks       => 0
  );
  
  -- Verification
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
      reset           => reset,
      ena             => ena,
      hh_dut          => hh_dut,
      mm_dut          => mm_dut,
      ss_dut          => ss_dut,
      pm_dut          => pm_dut,
      tb_match        => tb_match,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk   => clk,
      reset => reset,
      ena   => ena,
      pm    => pm_ref,
      hh    => hh_ref,
      mm    => mm_ref,
      ss    => ss_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk   => clk,
      reset => reset,
      ena   => ena,
      pm    => pm_dut,
      hh    => hh_dut,
      mm    => mm_dut,
      ss    => ss_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (pm_ref = pm_dut) and 
              (hh_ref = hh_dut) and 
              (mm_ref = mm_dut) and 
              (ss_ref = ss_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- CRITICAL: Only count mismatches when NOT sim_done
  -- This prevents spurious mismatches after stimulus completes
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      -- CRITICAL: Only count when simulation is NOT done
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Overall match check
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Individual output checks
        if pm_ref /= pm_dut then
          if stats1.errors_pm = 0 then
            stats1.errortime_pm <= now;
          end if;
          stats1.errors_pm <= stats1.errors_pm + 1;
        end if;
        
        if hh_ref /= hh_dut then
          if stats1.errors_hh = 0 then
            stats1.errortime_hh <= now;
          end if;
          stats1.errors_hh <= stats1.errors_hh + 1;
        end if;
        
        if mm_ref /= mm_dut then
          if stats1.errors_mm = 0 then
            stats1.errortime_mm <= now;
          end if;
          stats1.errors_mm <= stats1.errors_mm + 1;
        end if;
        
        if ss_ref /= ss_dut then
          if stats1.errors_ss = 0 then
            stats1.errortime_ss <= now;
          end if;
          stats1.errors_ss <= stats1.errors_ss + 1;
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
  -- CRITICAL: Wait for sim_done signal, NOT fixed timeout!
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- CRITICAL: Wait for stimulus completion (not fixed delay!)
    wait until sim_done;
    wait for 100 ps;  -- Allow final statistics to settle
    
    -- Write per-output summaries
    if stats1.errors_pm > 0 then
      write(l, string'("Hint: Output 'pm' has "));
      write(l, stats1.errors_pm);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_pm / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'pm' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_hh > 0 then
      write(l, string'("Hint: Output 'hh' has "));
      write(l, stats1.errors_hh);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_hh / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'hh' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_mm > 0 then
      write(l, string'("Hint: Output 'mm' has "));
      write(l, stats1.errors_mm);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_mm / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'mm' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_ss > 0 then
      write(l, string'("Hint: Output 'ss' has "));
      write(l, stats1.errors_ss);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_ss / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'ss' has no mismatches."));
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
    if stats1.errors_pm > 0 then
      info("Hint: Output 'pm' has " & integer'image(stats1.errors_pm) & 
           " mismatches. First at " & integer'image(stats1.errortime_pm / 1 ps) & " ps.");
    else
      info("Hint: Output 'pm' has no mismatches.");
    end if;
    
    if stats1.errors_hh > 0 then
      info("Hint: Output 'hh' has " & integer'image(stats1.errors_hh) & 
           " mismatches. First at " & integer'image(stats1.errortime_hh / 1 ps) & " ps.");
    else
      info("Hint: Output 'hh' has no mismatches.");
    end if;
    
    if stats1.errors_mm > 0 then
      info("Hint: Output 'mm' has " & integer'image(stats1.errors_mm) & 
           " mismatches. First at " & integer'image(stats1.errortime_mm / 1 ps) & " ps.");
    else
      info("Hint: Output 'mm' has no mismatches.");
    end if;
    
    if stats1.errors_ss > 0 then
      info("Hint: Output 'ss' has " & integer'image(stats1.errors_ss) & 
           " mismatches. First at " & integer'image(stats1.errortime_ss / 1 ps) & " ps.");
    else
      info("Hint: Output 'ss' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & integer'image(stats1.errors) & 
         " out of " & integer'image(stats1.clocks) & " samples");
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