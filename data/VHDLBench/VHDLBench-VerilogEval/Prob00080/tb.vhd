-- (2) Testbench (tb entity)
-- Main Testbench for Down-Counter Timer
-- Instantiates stimulus_gen, RefModule, and TopModule
-- Performs verification and generates summary.txt
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
  signal load : std_logic := '0';
  signal data : std_logic_vector(9 downto 0) := (others => '0');
  signal tc_ref : std_logic;
  signal tc_dut : std_logic;
  
  -- Stimulus control
  signal wavedrom_title : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal wavedrom_hide_after_time : integer;
  signal sim_done : boolean := false;
  
  -- Statistics type (matches Verilog struct stats)
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_tc      : integer;
    errortime_tc   : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_tc     => 0,
    errortime_tc  => 0 ps,
    clocks        => 0
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
  -- Matches Verilog: stimulus_gen stim1 (.clk, .*, .load, .data);
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk                     => clk,
      load                    => load,
      data                    => data,
      tb_match                => tb_match,
      wavedrom_title          => wavedrom_title,
      wavedrom_enable         => wavedrom_enable,
      wavedrom_hide_after_time => wavedrom_hide_after_time,
      sim_done                => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -- Matches Verilog: RefModule good1 (.clk, .load, .data, .tc(tc_ref));
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk  => clk,
      load => load,
      data => data,
      tc   => tc_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -- Matches Verilog: TopModule top_module1 (.clk, .load, .data, .tc(tc_dut));
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk  => clk,
      load => load,
      data => data,
      tc   => tc_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ tc_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match    <= (tc_ref = tc_dut);
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
        
        -- Check tc output
        -- Matches Verilog: if (tc_ref !== (tc_ref ^ tc_dut ^ tc_ref))
        if tc_ref /= tc_dut then
          if stats1.errors_tc = 0 then
            stats1.errortime_tc <= now;
          end if;
          stats1.errors_tc <= stats1.errors_tc + 1;
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
    -- Wait for timeout (matches Verilog timeout: #1000000)
    wait for 1000000 ps;
    
    -- Generate summary.txt (matches Verilog final block)
    if stats1.errors_tc > 0 then
      write(l, string'("Hint: Output 'tc' has "));
      write(l, stats1.errors_tc);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_tc / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'tc' has no mismatches."));
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
    
    -- Console output (matches Verilog $display)
    info("========================================");
    if stats1.errors_tc > 0 then
      info("Hint: Output 'tc' has " & integer'image(stats1.errors_tc) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_tc / 1 ps) & " ps.");
    else
      info("Hint: Output 'tc' has no mismatches.");
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