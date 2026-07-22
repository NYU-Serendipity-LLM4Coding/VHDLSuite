-- (2) Testbench (tb entity)
-- Main Testbench for Hierarchical Module Design
-- Tests combinational logic with submodules
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
  
  signal clk : std_logic := '0';
  constant clk_period : time := 10 ps;
  
  signal x       : std_logic := '0';
  signal y       : std_logic := '0';
  signal z_ref   : std_logic;
  signal z_dut   : std_logic;
  
  signal sim_done : boolean := false;
  
  type stats_t is record
    errors        : integer;
    errortime     : time;
    errors_z      : integer;
    errortime_z   : time;
    clocks        : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors      => 0,
    errortime   => 0 ps,
    errors_z    => 0,
    errortime_z => 0 ps,
    clocks      => 0
  );
  
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
begin

  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;
  
  stim1 : entity work.stimulus_gen
    port map (
      clk      => clk,
      x        => x,
      y        => y,
      sim_done => sim_done
    );
  
  good1 : entity work.RefModule
    port map (
      x => x,
      y => y,
      z => z_ref
    );
  
  top_module1 : entity work.TopModule
    port map (
      x => x,
      y => y,
      z => z_dut
    );
  
  tb_match    <= (z_ref = z_dut);
  tb_mismatch <= not tb_match;
  
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        if z_ref /= z_dut then
          if stats1.errors_z = 0 then
            stats1.errortime_z <= now;
          end if;
          stats1.errors_z <= stats1.errors_z + 1;
        end if;
      end if;
    end if;
  end process;
  
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 1000000 ps;
    
    if stats1.errors_z > 0 then
      write(l, string'("Hint: Output 'z' has "));
      write(l, stats1.errors_z);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_z / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'z' has no mismatches."));
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
    
    info("========================================");
    if stats1.errors_z > 0 then
      info("Hint: Output 'z' has " & integer'image(stats1.errors_z) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_z / 1 ps) & " ps.");
    else
      info("Hint: Output 'z' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
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