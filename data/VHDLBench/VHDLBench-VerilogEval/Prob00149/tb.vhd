-- (2) Testbench (tb entity)
-- Main Testbench for Water Level FSM
-- Verifies fr3, fr2, fr1, and dfr outputs
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
  signal reset   : std_logic := '0';
  signal s       : std_logic_vector(3 downto 1) := "000";
  signal fr3_ref : std_logic;
  signal fr3_dut : std_logic;
  signal fr2_ref : std_logic;
  signal fr2_dut : std_logic;
  signal fr1_ref : std_logic;
  signal fr1_dut : std_logic;
  signal dfr_ref : std_logic;
  signal dfr_dut : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (4 outputs)
  type stats_t is record
    errors            : integer;
    errortime         : time;
    errors_fr3        : integer;
    errortime_fr3     : time;
    errors_fr2        : integer;
    errortime_fr2     : time;
    errors_fr1        : integer;
    errortime_fr1     : time;
    errors_dfr        : integer;
    errortime_dfr     : time;
    clocks            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_fr3    => 0,
    errortime_fr3 => 0 ps,
    errors_fr2    => 0,
    errortime_fr2 => 0 ps,
    errors_fr1    => 0,
    errortime_fr1 => 0 ps,
    errors_dfr    => 0,
    errortime_dfr => 0 ps,
    clocks        => 0
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
      reset           => reset,
      s               => s,
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
      clk   => clk,
      reset => reset,
      s     => s,
      fr3   => fr3_ref,
      fr2   => fr2_ref,
      fr1   => fr1_ref,
      dfr   => dfr_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk   => clk,
      reset => reset,
      s     => s,
      fr3   => fr3_dut,
      fr2   => fr2_dut,
      fr1   => fr1_dut,
      dfr   => dfr_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (fr3_ref = fr3_dut) and 
              (fr2_ref = fr2_dut) and
              (fr1_ref = fr1_dut) and
              (dfr_ref = dfr_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- CRITICAL: Only count mismatches when sim_done = false
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Overall match
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Check fr3
        if fr3_ref /= fr3_dut then
          if stats1.errors_fr3 = 0 then
            stats1.errortime_fr3 <= now;
          end if;
          stats1.errors_fr3 <= stats1.errors_fr3 + 1;
        end if;
        
        -- Check fr2
        if fr2_ref /= fr2_dut then
          if stats1.errors_fr2 = 0 then
            stats1.errortime_fr2 <= now;
          end if;
          stats1.errors_fr2 <= stats1.errors_fr2 + 1;
        end if;
        
        -- Check fr1
        if fr1_ref /= fr1_dut then
          if stats1.errors_fr1 = 0 then
            stats1.errortime_fr1 <= now;
          end if;
          stats1.errors_fr1 <= stats1.errors_fr1 + 1;
        end if;
        
        -- Check dfr
        if dfr_ref /= dfr_dut then
          if stats1.errors_dfr = 0 then
            stats1.errortime_dfr <= now;
          end if;
          stats1.errors_dfr <= stats1.errors_dfr + 1;
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
    
    -- Write summary for fr3
    if stats1.errors_fr3 > 0 then
      write(l, string'("Hint: Output 'fr3' has "));
      write(l, stats1.errors_fr3);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_fr3 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'fr3' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for fr2
    if stats1.errors_fr2 > 0 then
      write(l, string'("Hint: Output 'fr2' has "));
      write(l, stats1.errors_fr2);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_fr2 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'fr2' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for fr1
    if stats1.errors_fr1 > 0 then
      write(l, string'("Hint: Output 'fr1' has "));
      write(l, stats1.errors_fr1);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_fr1 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'fr1' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for dfr
    if stats1.errors_dfr > 0 then
      write(l, string'("Hint: Output 'dfr' has "));
      write(l, stats1.errors_dfr);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_dfr / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'dfr' has no mismatches."));
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
    if stats1.errors_fr3 > 0 then
      info("Hint: Output 'fr3' has " & integer'image(stats1.errors_fr3) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_fr3 / 1 ps) & " ps.");
    else
      info("Hint: Output 'fr3' has no mismatches.");
    end if;
    
    if stats1.errors_fr2 > 0 then
      info("Hint: Output 'fr2' has " & integer'image(stats1.errors_fr2) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_fr2 / 1 ps) & " ps.");
    else
      info("Hint: Output 'fr2' has no mismatches.");
    end if;
    
    if stats1.errors_fr1 > 0 then
      info("Hint: Output 'fr1' has " & integer'image(stats1.errors_fr1) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_fr1 / 1 ps) & " ps.");
    else
      info("Hint: Output 'fr1' has no mismatches.");
    end if;
    
    if stats1.errors_dfr > 0 then
      info("Hint: Output 'dfr' has " & integer'image(stats1.errors_dfr) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_dfr / 1 ps) & " ps.");
    else
      info("Hint: Output 'dfr' has no mismatches.");
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