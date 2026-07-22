-- (2) Testbench (tb entity)
-- Main Testbench for Combinational Logic Bug Fix
-- Verifies shut_off_computer and keep_driving outputs
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
  signal cpu_overheated        : std_logic := '0';
  signal arrived               : std_logic := '0';
  signal gas_tank_empty        : std_logic := '0';
  signal shut_off_computer_ref : std_logic;
  signal shut_off_computer_dut : std_logic;
  signal keep_driving_ref      : std_logic;
  signal keep_driving_dut      : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for two outputs)
  type stats_t is record
    errors                       : integer;
    errortime                    : time;
    errors_shut_off_computer     : integer;
    errortime_shut_off_computer  : time;
    errors_keep_driving          : integer;
    errortime_keep_driving       : time;
    clocks                       : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors                      => 0,
    errortime                   => 0 ps,
    errors_shut_off_computer    => 0,
    errortime_shut_off_computer => 0 ps,
    errors_keep_driving         => 0,
    errortime_keep_driving      => 0 ps,
    clocks                      => 0
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
      cpu_overheated  => cpu_overheated,
      arrived         => arrived,
      gas_tank_empty  => gas_tank_empty,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      cpu_overheated   => cpu_overheated,
      arrived          => arrived,
      gas_tank_empty   => gas_tank_empty,
      shut_off_computer => shut_off_computer_ref,
      keep_driving     => keep_driving_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      cpu_overheated   => cpu_overheated,
      arrived          => arrived,
      gas_tank_empty   => gas_tank_empty,
      shut_off_computer => shut_off_computer_dut,
      keep_driving     => keep_driving_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (shut_off_computer_ref = shut_off_computer_dut) and 
              (keep_driving_ref = keep_driving_dut);
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
        
        -- Check shut_off_computer
        if shut_off_computer_ref /= shut_off_computer_dut then
          if stats1.errors_shut_off_computer = 0 then
            stats1.errortime_shut_off_computer <= now;
          end if;
          stats1.errors_shut_off_computer <= stats1.errors_shut_off_computer + 1;
        end if;
        
        -- Check keep_driving
        if keep_driving_ref /= keep_driving_dut then
          if stats1.errors_keep_driving = 0 then
            stats1.errortime_keep_driving <= now;
          end if;
          stats1.errors_keep_driving <= stats1.errors_keep_driving + 1;
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
    
    -- Write summary for shut_off_computer
    if stats1.errors_shut_off_computer > 0 then
      write(l, string'("Hint: Output 'shut_off_computer' has "));
      write(l, stats1.errors_shut_off_computer);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_shut_off_computer / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'shut_off_computer' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for keep_driving
    if stats1.errors_keep_driving > 0 then
      write(l, string'("Hint: Output 'keep_driving' has "));
      write(l, stats1.errors_keep_driving);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_keep_driving / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'keep_driving' has no mismatches."));
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
    if stats1.errors_shut_off_computer > 0 then
      info("Hint: Output 'shut_off_computer' has " & integer'image(stats1.errors_shut_off_computer) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_shut_off_computer / 1 ps) & " ps.");
    else
      info("Hint: Output 'shut_off_computer' has no mismatches.");
    end if;
    
    if stats1.errors_keep_driving > 0 then
      info("Hint: Output 'keep_driving' has " & integer'image(stats1.errors_keep_driving) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_keep_driving / 1 ps) & " ps.");
    else
      info("Hint: Output 'keep_driving' has no mismatches.");
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