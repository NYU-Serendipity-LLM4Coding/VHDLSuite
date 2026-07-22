-- (2) Testbench (tb entity)
-- Main Testbench for Thermostat Controller
-- Verifies heater, aircon, and fan outputs
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
  
  -- Input signals
  signal mode      : std_logic := '0';
  signal too_cold  : std_logic := '0';
  signal too_hot   : std_logic := '0';
  signal fan_on    : std_logic := '0';
  
  -- Reference outputs
  signal heater_ref : std_logic;
  signal aircon_ref : std_logic;
  signal fan_ref    : std_logic;
  
  -- DUT outputs
  signal heater_dut : std_logic;
  signal aircon_dut : std_logic;
  signal fan_dut    : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors              : integer;
    errortime           : time;
    errors_heater       : integer;
    errortime_heater    : time;
    errors_aircon       : integer;
    errortime_aircon    : time;
    errors_fan          : integer;
    errortime_fan       : time;
    clocks              : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors           => 0,
    errortime        => 0 ps,
    errors_heater    => 0,
    errortime_heater => 0 ps,
    errors_aircon    => 0,
    errortime_aircon => 0 ps,
    errors_fan       => 0,
    errortime_fan    => 0 ps,
    clocks           => 0
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
      too_cold        => too_cold,
      too_hot         => too_hot,
      mode            => mode,
      fan_on          => fan_on,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      mode    => mode,
      too_cold => too_cold,
      too_hot  => too_hot,
      fan_on   => fan_on,
      heater   => heater_ref,
      aircon   => aircon_ref,
      fan      => fan_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      mode    => mode,
      too_cold => too_cold,
      too_hot  => too_hot,
      fan_on   => fan_on,
      heater   => heater_dut,
      aircon   => aircon_dut,
      fan      => fan_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (heater_ref = heater_dut) and 
              (aircon_ref = aircon_dut) and 
              (fan_ref = fan_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
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
        
        -- Check heater output
        if heater_ref /= heater_dut then
          if stats1.errors_heater = 0 then
            stats1.errortime_heater <= now;
          end if;
          stats1.errors_heater <= stats1.errors_heater + 1;
        end if;
        
        -- Check aircon output
        if aircon_ref /= aircon_dut then
          if stats1.errors_aircon = 0 then
            stats1.errortime_aircon <= now;
          end if;
          stats1.errors_aircon <= stats1.errors_aircon + 1;
        end if;
        
        -- Check fan output
        if fan_ref /= fan_dut then
          if stats1.errors_fan = 0 then
            stats1.errortime_fan <= now;
          end if;
          stats1.errors_fan <= stats1.errors_fan + 1;
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
    
    -- Write summary for heater
    if stats1.errors_heater > 0 then
      write(l, string'("Hint: Output 'heater' has "));
      write(l, stats1.errors_heater);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_heater / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'heater' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for aircon
    if stats1.errors_aircon > 0 then
      write(l, string'("Hint: Output 'aircon' has "));
      write(l, stats1.errors_aircon);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_aircon / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'aircon' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for fan
    if stats1.errors_fan > 0 then
      write(l, string'("Hint: Output 'fan' has "));
      write(l, stats1.errors_fan);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_fan / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'fan' has no mismatches."));
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
    if stats1.errors_heater > 0 then
      info("Hint: Output 'heater' has " & integer'image(stats1.errors_heater) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_heater / 1 ps) & " ps.");
    else
      info("Hint: Output 'heater' has no mismatches.");
    end if;
    
    if stats1.errors_aircon > 0 then
      info("Hint: Output 'aircon' has " & integer'image(stats1.errors_aircon) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_aircon / 1 ps) & " ps.");
    else
      info("Hint: Output 'aircon' has no mismatches.");
    end if;
    
    if stats1.errors_fan > 0 then
      info("Hint: Output 'fan' has " & integer'image(stats1.errors_fan) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_fan / 1 ps) & " ps.");
    else
      info("Hint: Output 'fan' has no mismatches.");
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