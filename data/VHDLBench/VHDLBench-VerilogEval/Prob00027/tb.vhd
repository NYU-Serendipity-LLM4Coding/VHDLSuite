-- (2) Testbench (tb entity)
-- Main Testbench for Full Adder
-- Verifies both cout and sum outputs
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
  constant clk_period : time := 10 ps;  -- Matches Verilog: #5 clk = ~clk
  
  -- DUT signals
  signal a        : std_logic := '0';
  signal b        : std_logic := '0';
  signal cin      : std_logic := '0';
  signal cout_ref : std_logic;
  signal cout_dut : std_logic;
  signal sum_ref  : std_logic;
  signal sum_dut  : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for cout and sum outputs)
  type stats_t is record
    errors            : integer;
    errortime         : time;
    errors_cout       : integer;
    errortime_cout    : time;
    errors_sum        : integer;
    errortime_sum     : time;
    clocks            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors         => 0,
    errortime      => 0 ps,
    errors_cout    => 0,
    errortime_cout => 0 ps,
    errors_sum     => 0,
    errortime_sum  => 0 ps,
    clocks         => 0
  );
  
  -- Verification signals
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation
  -- Matches Verilog: initial forever #5 clk = ~clk;
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
      cin             => cin,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      a    => a,
      b    => b,
      cin  => cin,
      cout => cout_ref,
      sum  => sum_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      a    => a,
      b    => b,
      cin  => cin,
      cout => cout_dut,
      sum  => sum_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ cout_ref, sum_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (cout_ref = cout_dut) and (sum_ref = sum_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
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
        
        -- Check cout
        if cout_ref /= cout_dut then
          if stats1.errors_cout = 0 then
            stats1.errortime_cout <= now;
          end if;
          stats1.errors_cout <= stats1.errors_cout + 1;
        end if;
        
        -- Check sum
        if sum_ref /= sum_dut then
          if stats1.errors_sum = 0 then
            stats1.errortime_sum <= now;
          end if;
          stats1.errors_sum <= stats1.errors_sum + 1;
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
    wait;  -- Wait for report process to cleanup
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -- Matches Verilog: final begin ... end
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for timeout (matches Verilog: #1000000)
    wait for 1000000 ps;
    
    -- Generate summary.txt (matches Verilog final block)
    
    -- Report for cout
    if stats1.errors_cout > 0 then
      write(l, string'("Hint: Output 'cout' has "));
      write(l, stats1.errors_cout);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_cout / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'cout' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Report for sum
    if stats1.errors_sum > 0 then
      write(l, string'("Hint: Output 'sum' has "));
      write(l, stats1.errors_sum);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_sum / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'sum' has no mismatches."));
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
    
    -- Console output (matches Verilog $display)
    info("========================================");
    if stats1.errors_cout > 0 then
      info("Hint: Output 'cout' has " & integer'image(stats1.errors_cout) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_cout / 1 ps) & " ps.");
    else
      info("Hint: Output 'cout' has no mismatches.");
    end if;
    
    if stats1.errors_sum > 0 then
      info("Hint: Output 'sum' has " & integer'image(stats1.errors_sum) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_sum / 1 ps) & " ps.");
    else
      info("Hint: Output 'sum' has no mismatches.");
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