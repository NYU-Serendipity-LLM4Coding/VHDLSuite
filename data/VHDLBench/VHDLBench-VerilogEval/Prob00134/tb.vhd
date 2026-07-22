-- (2) Testbench (tb entity)
-- Main Testbench for State Machine Logic Functions
-- Verifies Y0 and z outputs against reference implementation
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
  signal x       : std_logic := '0';
  signal y       : std_logic_vector(2 downto 0) := "000";
  signal Y0_ref  : std_logic;
  signal Y0_dut  : std_logic;
  signal z_ref   : std_logic;
  signal z_dut   : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type (matches Verilog struct stats)
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_Y0      : integer;
    errortime_Y0   : time;
    errors_z       : integer;
    errortime_z    : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_Y0     => 0,
    errortime_Y0  => 0 ps,
    errors_z      => 0,
    errortime_z   => 0 ps,
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
      clk      => clk,
      x        => x,
      y        => y,
      sim_done => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk => clk,
      x   => x,
      y   => y,
      Y0  => Y0_ref,
      z   => z_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk => clk,
      x   => x,
      y   => y,
      Y0  => Y0_dut,
      z   => z_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ Y0_ref, z_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match    <= (Y0_ref = Y0_dut) and (z_ref = z_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -- CRITICAL: Only count when sim_done is false to prevent spurious mismatches
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
        
        -- Check Y0 output
        if Y0_ref /= Y0_dut then
          if stats1.errors_Y0 = 0 then
            stats1.errortime_Y0 <= now;
          end if;
          stats1.errors_Y0 <= stats1.errors_Y0 + 1;
        end if;
        
        -- Check z output
        if z_ref /= z_dut then
          if stats1.errors_z = 0 then
            stats1.errortime_z <= now;
          end if;
          stats1.errors_z <= stats1.errors_z + 1;
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
    -- Wait for timeout (matches Verilog timeout: #1000000)
    wait for 1000000 ps;
    
    -- Generate summary.txt (matches Verilog final block)
    if stats1.errors_Y0 > 0 then
      write(l, string'("Hint: Output 'Y0' has "));
      write(l, stats1.errors_Y0);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Y0 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Y0' has no mismatches."));
      writeline(f, l);
    end if;
    
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
    
    -- Console output
    info("========================================");
    if stats1.errors_Y0 > 0 then
      info("Hint: Output 'Y0' has " & integer'image(stats1.errors_Y0) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_Y0 / 1 ps) & " ps.");
    else
      info("Hint: Output 'Y0' has no mismatches.");
    end if;
    
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