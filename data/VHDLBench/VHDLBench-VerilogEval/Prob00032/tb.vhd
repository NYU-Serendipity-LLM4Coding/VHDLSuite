-- (2) Testbench (tb entity)
-- Main Testbench for Vector Splitter
-- Verifies vector passthrough and individual bit outputs
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
  signal vec      : std_logic_vector(2 downto 0) := "000";
  signal outv_ref : std_logic_vector(2 downto 0);
  signal outv_dut : std_logic_vector(2 downto 0);
  signal o2_ref   : std_logic;
  signal o2_dut   : std_logic;
  signal o1_ref   : std_logic;
  signal o1_dut   : std_logic;
  signal o0_ref   : std_logic;
  signal o0_dut   : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for multiple outputs)
  type stats_t is record
    errors           : integer;
    errortime        : time;
    errors_outv      : integer;
    errortime_outv   : time;
    errors_o2        : integer;
    errortime_o2     : time;
    errors_o1        : integer;
    errortime_o1     : time;
    errors_o0        : integer;
    errortime_o0     : time;
    clocks           : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors         => 0,
    errortime      => 0 ps,
    errors_outv    => 0,
    errortime_outv => 0 ps,
    errors_o2      => 0,
    errortime_o2   => 0 ps,
    errors_o1      => 0,
    errortime_o1   => 0 ps,
    errors_o0      => 0,
    errortime_o0   => 0 ps,
    clocks         => 0
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
      vec             => vec,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      vec  => vec,
      outv => outv_ref,
      o2   => o2_ref,
      o1   => o1_ref,
      o0   => o0_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      vec  => vec,
      outv => outv_dut,
      o2   => o2_dut,
      o1   => o1_dut,
      o0   => o0_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ outv_ref, o2_ref, o1_ref, o0_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (outv_ref = outv_dut) and 
              (o2_ref = o2_dut) and 
              (o1_ref = o1_dut) and 
              (o0_ref = o0_dut);
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
        
        -- Check outv
        if outv_ref /= outv_dut then
          if stats1.errors_outv = 0 then
            stats1.errortime_outv <= now;
          end if;
          stats1.errors_outv <= stats1.errors_outv + 1;
        end if;
        
        -- Check o2
        if o2_ref /= o2_dut then
          if stats1.errors_o2 = 0 then
            stats1.errortime_o2 <= now;
          end if;
          stats1.errors_o2 <= stats1.errors_o2 + 1;
        end if;
        
        -- Check o1
        if o1_ref /= o1_dut then
          if stats1.errors_o1 = 0 then
            stats1.errortime_o1 <= now;
          end if;
          stats1.errors_o1 <= stats1.errors_o1 + 1;
        end if;
        
        -- Check o0
        if o0_ref /= o0_dut then
          if stats1.errors_o0 = 0 then
            stats1.errortime_o0 <= now;
          end if;
          stats1.errors_o0 <= stats1.errors_o0 + 1;
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
    
    -- Write summary for outv
    if stats1.errors_outv > 0 then
      write(l, string'("Hint: Output 'outv' has "));
      write(l, stats1.errors_outv);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_outv / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'outv' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for o2
    if stats1.errors_o2 > 0 then
      write(l, string'("Hint: Output 'o2' has "));
      write(l, stats1.errors_o2);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_o2 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'o2' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for o1
    if stats1.errors_o1 > 0 then
      write(l, string'("Hint: Output 'o1' has "));
      write(l, stats1.errors_o1);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_o1 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'o1' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for o0
    if stats1.errors_o0 > 0 then
      write(l, string'("Hint: Output 'o0' has "));
      write(l, stats1.errors_o0);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_o0 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'o0' has no mismatches."));
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
    if stats1.errors_outv > 0 then
      info("Hint: Output 'outv' has " & integer'image(stats1.errors_outv) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_outv / 1 ps) & " ps.");
    else
      info("Hint: Output 'outv' has no mismatches.");
    end if;
    
    if stats1.errors_o2 > 0 then
      info("Hint: Output 'o2' has " & integer'image(stats1.errors_o2) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_o2 / 1 ps) & " ps.");
    else
      info("Hint: Output 'o2' has no mismatches.");
    end if;
    
    if stats1.errors_o1 > 0 then
      info("Hint: Output 'o1' has " & integer'image(stats1.errors_o1) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_o1 / 1 ps) & " ps.");
    else
      info("Hint: Output 'o1' has no mismatches.");
    end if;
    
    if stats1.errors_o0 > 0 then
      info("Hint: Output 'o0' has " & integer'image(stats1.errors_o0) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_o0 / 1 ps) & " ps.");
    else
      info("Hint: Output 'o0' has no mismatches.");
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