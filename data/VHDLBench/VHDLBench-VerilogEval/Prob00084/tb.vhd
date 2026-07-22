-- (2) Testbench (tb entity)
-- Main Testbench for 8-bit Shift Register with Mux
-- Verifies shift register and multiplexer functionality
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
  signal enable : std_logic := '0';
  signal S      : std_logic := '0';
  signal A      : std_logic := '0';
  signal B      : std_logic := '0';
  signal C      : std_logic := '0';
  signal Z_ref  : std_logic;
  signal Z_dut  : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors        : integer;
    errortime     : time;
    errors_Z      : integer;
    errortime_Z   : time;
    clocks        : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors      => 0,
    errortime   => 0 ps,
    errors_Z    => 0,
    errortime_Z => 0 ps,
    clocks      => 0
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
      S               => S,
      enable          => enable,
      A               => A,
      B               => B,
      C               => C,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk    => clk,
      enable => enable,
      S      => S,
      A      => A,
      B      => B,
      C      => C,
      Z      => Z_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk    => clk,
      enable => enable,
      S      => S,
      A      => A,
      B      => B,
      C      => C,
      Z      => Z_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match    <= (Z_ref = Z_dut) or (Z_ref = 'X') or (Z_ref = 'U');
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- CRITICAL: Only count when sim_done = false to prevent extra mismatches
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
        
        -- Check Z output specifically
        if Z_ref /= Z_dut and Z_ref /= 'X' and Z_ref /= 'U' then
          if stats1.errors_Z = 0 then
            stats1.errortime_Z <= now;
          end if;
          stats1.errors_Z <= stats1.errors_Z + 1;
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
    
    -- Write summary for Z
    if stats1.errors_Z > 0 then
      write(l, string'("Hint: Output 'Z' has "));
      write(l, stats1.errors_Z);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Z / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Z' has no mismatches."));
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
    
    -- Console output
    info("========================================");
    if stats1.errors_Z > 0 then
      info("Hint: Output 'Z' has " & integer'image(stats1.errors_Z) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_Z / 1 ps) & " ps.");
    else
      info("Hint: Output 'Z' has no mismatches.");
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