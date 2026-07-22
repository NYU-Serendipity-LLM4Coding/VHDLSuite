-- (2) Testbench (tb entity)
-- Main Testbench for Bitwise/Logical OR and NOT operations
-- Verifies out_or_bitwise, out_or_logical, and out_not outputs
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
  signal a                  : std_logic_vector(2 downto 0) := "000";
  signal b                  : std_logic_vector(2 downto 0) := "000";
  signal out_or_bitwise_ref : std_logic_vector(2 downto 0);
  signal out_or_bitwise_dut : std_logic_vector(2 downto 0);
  signal out_or_logical_ref : std_logic;
  signal out_or_logical_dut : std_logic;
  signal out_not_ref        : std_logic_vector(5 downto 0);
  signal out_not_dut        : std_logic_vector(5 downto 0);
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for three outputs)
  type stats_t is record
    errors                    : integer;
    errortime                 : time;
    errors_out_or_bitwise     : integer;
    errortime_out_or_bitwise  : time;
    errors_out_or_logical     : integer;
    errortime_out_or_logical  : time;
    errors_out_not            : integer;
    errortime_out_not         : time;
    clocks                    : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors                   => 0,
    errortime                => 0 ps,
    errors_out_or_bitwise    => 0,
    errortime_out_or_bitwise => 0 ps,
    errors_out_or_logical    => 0,
    errortime_out_or_logical => 0 ps,
    errors_out_not           => 0,
    errortime_out_not        => 0 ps,
    clocks                   => 0
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
      a               => a,
      b               => b,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      a              => a,
      b              => b,
      out_or_bitwise => out_or_bitwise_ref,
      out_or_logical => out_or_logical_ref,
      out_not        => out_not_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      a              => a,
      b              => b,
      out_or_bitwise => out_or_bitwise_dut,
      out_or_logical => out_or_logical_dut,
      out_not        => out_not_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (out_or_bitwise_ref = out_or_bitwise_dut) and 
              (out_or_logical_ref = out_or_logical_dut) and
              (out_not_ref = out_not_dut);
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
        
        -- Check out_or_bitwise
        if out_or_bitwise_ref /= out_or_bitwise_dut then
          if stats1.errors_out_or_bitwise = 0 then
            stats1.errortime_out_or_bitwise <= now;
          end if;
          stats1.errors_out_or_bitwise <= stats1.errors_out_or_bitwise + 1;
        end if;
        
        -- Check out_or_logical
        if out_or_logical_ref /= out_or_logical_dut then
          if stats1.errors_out_or_logical = 0 then
            stats1.errortime_out_or_logical <= now;
          end if;
          stats1.errors_out_or_logical <= stats1.errors_out_or_logical + 1;
        end if;
        
        -- Check out_not
        if out_not_ref /= out_not_dut then
          if stats1.errors_out_not = 0 then
            stats1.errortime_out_not <= now;
          end if;
          stats1.errors_out_not <= stats1.errors_out_not + 1;
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
    
    -- Write summary for out_or_bitwise
    if stats1.errors_out_or_bitwise > 0 then
      write(l, string'("Hint: Output 'out_or_bitwise' has "));
      write(l, stats1.errors_out_or_bitwise);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_or_bitwise / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_or_bitwise' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out_or_logical
    if stats1.errors_out_or_logical > 0 then
      write(l, string'("Hint: Output 'out_or_logical' has "));
      write(l, stats1.errors_out_or_logical);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_or_logical / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_or_logical' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out_not
    if stats1.errors_out_not > 0 then
      write(l, string'("Hint: Output 'out_not' has "));
      write(l, stats1.errors_out_not);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_not / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_not' has no mismatches."));
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
    if stats1.errors_out_or_bitwise > 0 then
      info("Hint: Output 'out_or_bitwise' has " & integer'image(stats1.errors_out_or_bitwise) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_or_bitwise / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_or_bitwise' has no mismatches.");
    end if;
    
    if stats1.errors_out_or_logical > 0 then
      info("Hint: Output 'out_or_logical' has " & integer'image(stats1.errors_out_or_logical) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_or_logical / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_or_logical' has no mismatches.");
    end if;
    
    if stats1.errors_out_not > 0 then
      info("Hint: Output 'out_not' has " & integer'image(stats1.errors_out_not) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_not / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_not' has no mismatches.");
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