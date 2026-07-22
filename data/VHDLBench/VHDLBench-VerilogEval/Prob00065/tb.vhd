-- (2) Testbench (tb entity)
-- Main Testbench for 7420 Dual 4-input NAND Gate
-- Verifies both p1y and p2y outputs
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
  signal p1a : std_logic := '0';
  signal p1b : std_logic := '0';
  signal p1c : std_logic := '0';
  signal p1d : std_logic := '0';
  signal p2a : std_logic := '0';
  signal p2b : std_logic := '0';
  signal p2c : std_logic := '0';
  signal p2d : std_logic := '0';
  
  signal p1y_ref : std_logic;
  signal p1y_dut : std_logic;
  signal p2y_ref : std_logic;
  signal p2y_dut : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors           : integer;
    errortime        : time;
    errors_p1y       : integer;
    errortime_p1y    : time;
    errors_p2y       : integer;
    errortime_p2y    : time;
    clocks           : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_p1y    => 0,
    errortime_p1y => 0 ps,
    errors_p2y    => 0,
    errortime_p2y => 0 ps,
    clocks        => 0
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
      p1a             => p1a,
      p1b             => p1b,
      p1c             => p1c,
      p1d             => p1d,
      p2a             => p2a,
      p2b             => p2b,
      p2c             => p2c,
      p2d             => p2d,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      p1a => p1a,
      p1b => p1b,
      p1c => p1c,
      p1d => p1d,
      p2a => p2a,
      p2b => p2b,
      p2c => p2c,
      p2d => p2d,
      p1y => p1y_ref,
      p2y => p2y_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      p1a => p1a,
      p1b => p1b,
      p1c => p1c,
      p1d => p1d,
      p2a => p2a,
      p2b => p2b,
      p2c => p2c,
      p2d => p2d,
      p1y => p1y_dut,
      p2y => p2y_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ p1y_ref, p2y_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (p1y_ref = p1y_dut) and (p2y_ref = p2y_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -- CRITICAL: Only count when sim_done is false to prevent extra mismatches
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
        
        -- Check p1y output
        if p1y_ref /= p1y_dut then
          if stats1.errors_p1y = 0 then
            stats1.errortime_p1y <= now;
          end if;
          stats1.errors_p1y <= stats1.errors_p1y + 1;
        end if;
        
        -- Check p2y output
        if p2y_ref /= p2y_dut then
          if stats1.errors_p2y = 0 then
            stats1.errortime_p2y <= now;
          end if;
          stats1.errors_p2y <= stats1.errors_p2y + 1;
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
    
    -- Write summary for p1y
    if stats1.errors_p1y > 0 then
      write(l, string'("Hint: Output 'p1y' has "));
      write(l, stats1.errors_p1y);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_p1y / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'p1y' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for p2y
    if stats1.errors_p2y > 0 then
      write(l, string'("Hint: Output 'p2y' has "));
      write(l, stats1.errors_p2y);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_p2y / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'p2y' has no mismatches."));
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
    if stats1.errors_p1y > 0 then
      info("Hint: Output 'p1y' has " & integer'image(stats1.errors_p1y) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_p1y / 1 ps) & " ps.");
    else
      info("Hint: Output 'p1y' has no mismatches.");
    end if;
    
    if stats1.errors_p2y > 0 then
      info("Hint: Output 'p2y' has " & integer'image(stats1.errors_p2y) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_p2y / 1 ps) & " ps.");
    else
      info("Hint: Output 'p2y' has no mismatches.");
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