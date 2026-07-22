-- (2) Testbench (tb entity)
-- Main Testbench for One-Hot State Machine
-- Verifies next_state, out1, and out2 outputs
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
  
  -- DUT signals (renamed 'in' to 'signal_in' - VHDL keyword)
  signal signal_in      : std_logic := '0';
  signal state          : std_logic_vector(9 downto 0) := (others => '0');
  signal next_state_ref : std_logic_vector(9 downto 0);
  signal next_state_dut : std_logic_vector(9 downto 0);
  signal out1_ref       : std_logic;
  signal out1_dut       : std_logic;
  signal out2_ref       : std_logic;
  signal out2_dut       : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors                  : integer;
    errortime               : time;
    errors_next_state       : integer;
    errortime_next_state    : time;
    errors_out1             : integer;
    errortime_out1          : time;
    errors_out2             : integer;
    errortime_out2          : time;
    clocks                  : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors               => 0,
    errortime            => 0 ps,
    errors_next_state    => 0,
    errortime_next_state => 0 ps,
    errors_out1          => 0,
    errortime_out1       => 0 ps,
    errors_out2          => 0,
    errortime_out2       => 0 ps,
    clocks               => 0
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
      signal_in       => signal_in,
      state           => state,
      tb_match        => tb_match,
      next_state_ref  => next_state_ref,
      next_state_dut  => next_state_dut,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      signal_in  => signal_in,
      state      => state,
      next_state => next_state_ref,
      out1       => out1_ref,
      out2       => out2_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      signal_in  => signal_in,
      state      => state,
      next_state => next_state_dut,
      out1       => out1_dut,
      out2       => out2_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ next_state_ref, out1_ref, out2_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (next_state_ref = next_state_dut) and 
              (out1_ref = out1_dut) and 
              (out2_ref = out2_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
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
        
        -- Check next_state
        if next_state_ref /= next_state_dut then
          if stats1.errors_next_state = 0 then
            stats1.errortime_next_state <= now;
          end if;
          stats1.errors_next_state <= stats1.errors_next_state + 1;
        end if;
        
        -- Check out1
        if out1_ref /= out1_dut then
          if stats1.errors_out1 = 0 then
            stats1.errortime_out1 <= now;
          end if;
          stats1.errors_out1 <= stats1.errors_out1 + 1;
        end if;
        
        -- Check out2
        if out2_ref /= out2_dut then
          if stats1.errors_out2 = 0 then
            stats1.errortime_out2 <= now;
          end if;
          stats1.errors_out2 <= stats1.errors_out2 + 1;
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
    
    -- Write summary for next_state
    if stats1.errors_next_state > 0 then
      write(l, string'("Hint: Output 'next_state' has "));
      write(l, stats1.errors_next_state);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_next_state / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'next_state' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out1
    if stats1.errors_out1 > 0 then
      write(l, string'("Hint: Output 'out1' has "));
      write(l, stats1.errors_out1);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out1 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out1' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out2
    if stats1.errors_out2 > 0 then
      write(l, string'("Hint: Output 'out2' has "));
      write(l, stats1.errors_out2);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out2 / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out2' has no mismatches."));
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
    if stats1.errors_next_state > 0 then
      info("Hint: Output 'next_state' has " & integer'image(stats1.errors_next_state) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_next_state / 1 ps) & " ps.");
    else
      info("Hint: Output 'next_state' has no mismatches.");
    end if;
    
    if stats1.errors_out1 > 0 then
      info("Hint: Output 'out1' has " & integer'image(stats1.errors_out1) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out1 / 1 ps) & " ps.");
    else
      info("Hint: Output 'out1' has no mismatches.");
    end if;
    
    if stats1.errors_out2 > 0 then
      info("Hint: Output 'out2' has " & integer'image(stats1.errors_out2) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out2 / 1 ps) & " ps.");
    else
      info("Hint: Output 'out2' has no mismatches.");
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