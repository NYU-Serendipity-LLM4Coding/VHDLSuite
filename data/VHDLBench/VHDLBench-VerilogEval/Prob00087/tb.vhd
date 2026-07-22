-- (2) Testbench (tb entity)
-- Main Testbench for Logic Gates
-- Verifies 7 different logic gate outputs
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
  signal a : std_logic := '0';
  signal b : std_logic := '0';
  
  -- Reference outputs
  signal out_and_ref   : std_logic;
  signal out_or_ref    : std_logic;
  signal out_xor_ref   : std_logic;
  signal out_nand_ref  : std_logic;
  signal out_nor_ref   : std_logic;
  signal out_xnor_ref  : std_logic;
  signal out_anotb_ref : std_logic;
  
  -- DUT outputs
  signal out_and_dut   : std_logic;
  signal out_or_dut    : std_logic;
  signal out_xor_dut   : std_logic;
  signal out_nand_dut  : std_logic;
  signal out_nor_dut   : std_logic;
  signal out_xnor_dut  : std_logic;
  signal out_anotb_dut : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for 7 outputs)
  type stats_t is record
    errors                : integer;
    errortime             : time;
    errors_out_and        : integer;
    errortime_out_and     : time;
    errors_out_or         : integer;
    errortime_out_or      : time;
    errors_out_xor        : integer;
    errortime_out_xor     : time;
    errors_out_nand       : integer;
    errortime_out_nand    : time;
    errors_out_nor        : integer;
    errortime_out_nor     : time;
    errors_out_xnor       : integer;
    errortime_out_xnor    : time;
    errors_out_anotb      : integer;
    errortime_out_anotb   : time;
    clocks                : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors               => 0,
    errortime            => 0 ps,
    errors_out_and       => 0,
    errortime_out_and    => 0 ps,
    errors_out_or        => 0,
    errortime_out_or     => 0 ps,
    errors_out_xor       => 0,
    errortime_out_xor    => 0 ps,
    errors_out_nand      => 0,
    errortime_out_nand   => 0 ps,
    errors_out_nor       => 0,
    errortime_out_nor    => 0 ps,
    errors_out_xnor      => 0,
    errortime_out_xnor   => 0 ps,
    errors_out_anotb     => 0,
    errortime_out_anotb  => 0 ps,
    clocks               => 0
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
      a          => a,
      b          => b,
      out_and    => out_and_ref,
      out_or     => out_or_ref,
      out_xor    => out_xor_ref,
      out_nand   => out_nand_ref,
      out_nor    => out_nor_ref,
      out_xnor   => out_xnor_ref,
      out_anotb  => out_anotb_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      a          => a,
      b          => b,
      out_and    => out_and_dut,
      out_or     => out_or_dut,
      out_xor    => out_xor_dut,
      out_nand   => out_nand_dut,
      out_nor    => out_nor_dut,
      out_xnor   => out_xnor_dut,
      out_anotb  => out_anotb_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (out_and_ref   = out_and_dut)   and 
              (out_or_ref    = out_or_dut)    and
              (out_xor_ref   = out_xor_dut)   and
              (out_nand_ref  = out_nand_dut)  and
              (out_nor_ref   = out_nor_dut)   and
              (out_xnor_ref  = out_xnor_dut)  and
              (out_anotb_ref = out_anotb_dut);
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
        
        -- Check each output individually
        if out_and_ref /= out_and_dut then
          if stats1.errors_out_and = 0 then
            stats1.errortime_out_and <= now;
          end if;
          stats1.errors_out_and <= stats1.errors_out_and + 1;
        end if;
        
        if out_or_ref /= out_or_dut then
          if stats1.errors_out_or = 0 then
            stats1.errortime_out_or <= now;
          end if;
          stats1.errors_out_or <= stats1.errors_out_or + 1;
        end if;
        
        if out_xor_ref /= out_xor_dut then
          if stats1.errors_out_xor = 0 then
            stats1.errortime_out_xor <= now;
          end if;
          stats1.errors_out_xor <= stats1.errors_out_xor + 1;
        end if;
        
        if out_nand_ref /= out_nand_dut then
          if stats1.errors_out_nand = 0 then
            stats1.errortime_out_nand <= now;
          end if;
          stats1.errors_out_nand <= stats1.errors_out_nand + 1;
        end if;
        
        if out_nor_ref /= out_nor_dut then
          if stats1.errors_out_nor = 0 then
            stats1.errortime_out_nor <= now;
          end if;
          stats1.errors_out_nor <= stats1.errors_out_nor + 1;
        end if;
        
        if out_xnor_ref /= out_xnor_dut then
          if stats1.errors_out_xnor = 0 then
            stats1.errortime_out_xnor <= now;
          end if;
          stats1.errors_out_xnor <= stats1.errors_out_xnor + 1;
        end if;
        
        if out_anotb_ref /= out_anotb_dut then
          if stats1.errors_out_anotb = 0 then
            stats1.errortime_out_anotb <= now;
          end if;
          stats1.errors_out_anotb <= stats1.errors_out_anotb + 1;
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
    
    -- Write summary for each output
    if stats1.errors_out_and > 0 then
      write(l, string'("Hint: Output 'out_and' has "));
      write(l, stats1.errors_out_and);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_and / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_and' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out_or > 0 then
      write(l, string'("Hint: Output 'out_or' has "));
      write(l, stats1.errors_out_or);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_or / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_or' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out_xor > 0 then
      write(l, string'("Hint: Output 'out_xor' has "));
      write(l, stats1.errors_out_xor);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_xor / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_xor' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out_nand > 0 then
      write(l, string'("Hint: Output 'out_nand' has "));
      write(l, stats1.errors_out_nand);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_nand / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_nand' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out_nor > 0 then
      write(l, string'("Hint: Output 'out_nor' has "));
      write(l, stats1.errors_out_nor);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_nor / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_nor' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out_xnor > 0 then
      write(l, string'("Hint: Output 'out_xnor' has "));
      write(l, stats1.errors_out_xnor);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_xnor / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_xnor' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_out_anotb > 0 then
      write(l, string'("Hint: Output 'out_anotb' has "));
      write(l, stats1.errors_out_anotb);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_anotb / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_anotb' has no mismatches."));
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
    if stats1.errors_out_and > 0 then
      info("Hint: Output 'out_and' has " & integer'image(stats1.errors_out_and) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_and / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_and' has no mismatches.");
    end if;
    
    if stats1.errors_out_or > 0 then
      info("Hint: Output 'out_or' has " & integer'image(stats1.errors_out_or) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_or / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_or' has no mismatches.");
    end if;
    
    if stats1.errors_out_xor > 0 then
      info("Hint: Output 'out_xor' has " & integer'image(stats1.errors_out_xor) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_xor / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_xor' has no mismatches.");
    end if;
    
    if stats1.errors_out_nand > 0 then
      info("Hint: Output 'out_nand' has " & integer'image(stats1.errors_out_nand) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_nand / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_nand' has no mismatches.");
    end if;
    
    if stats1.errors_out_nor > 0 then
      info("Hint: Output 'out_nor' has " & integer'image(stats1.errors_out_nor) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_nor / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_nor' has no mismatches.");
    end if;
    
    if stats1.errors_out_xnor > 0 then
      info("Hint: Output 'out_xnor' has " & integer'image(stats1.errors_out_xnor) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_xnor / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_xnor' has no mismatches.");
    end if;
    
    if stats1.errors_out_anotb > 0 then
      info("Hint: Output 'out_anotb' has " & integer'image(stats1.errors_out_anotb) & 
           " mismatches. First at time " & integer'image(stats1.errortime_out_anotb / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_anotb' has no mismatches.");
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