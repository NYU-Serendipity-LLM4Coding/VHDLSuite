-- (2) Testbench (tb entity)
-- Main Testbench for Serial Receiver FSM
-- Verifies both out_byte and done outputs
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
  
  -- DUT signals (renamed to avoid VHDL keywords)
  signal signal_in   : std_logic := '0';
  signal reset       : std_logic := '0';
  signal out_byte_ref: std_logic_vector(7 downto 0);
  signal out_byte_dut: std_logic_vector(7 downto 0);
  signal done_ref    : std_logic;
  signal done_dut    : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors               : integer;
    errortime            : time;
    errors_out_byte      : integer;
    errortime_out_byte   : time;
    errors_done          : integer;
    errortime_done       : time;
    clocks               : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors              => 0,
    errortime           => 0 ps,
    errors_out_byte     => 0,
    errortime_out_byte  => 0 ps,
    errors_done         => 0,
    errortime_done      => 0 ps,
    clocks              => 0
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
      clk       => clk,
      signal_in => signal_in,
      reset     => reset,
      sim_done  => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk      => clk,
      signal_in => signal_in,
      reset    => reset,
      out_byte => out_byte_ref,
      done     => done_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk      => clk,
      signal_in => signal_in,
      reset    => reset,
      out_byte => out_byte_dut,
      done     => done_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ out_byte_ref, done_ref } === ...)
  -- Note: Handles don't-care (X) values from reference
  -----------------------------------------------------------------------------
  tb_match <= ((out_byte_ref = out_byte_dut) or 
               (done_ref = '0' and out_byte_ref = "XXXXXXXX")) and 
              (done_ref = done_dut);
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
        
        -- Check out_byte (handle don't-care when done=0)
        if done_ref = '1' then
          if out_byte_ref /= out_byte_dut then
            if stats1.errors_out_byte = 0 then
              stats1.errortime_out_byte <= now;
            end if;
            stats1.errors_out_byte <= stats1.errors_out_byte + 1;
          end if;
        end if;
        
        -- Check done
        if done_ref /= done_dut then
          if stats1.errors_done = 0 then
            stats1.errortime_done <= now;
          end if;
          stats1.errors_done <= stats1.errors_done + 1;
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
    
    -- Write summary for out_byte
    if stats1.errors_out_byte > 0 then
      write(l, string'("Hint: Output 'out_byte' has "));
      write(l, stats1.errors_out_byte);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_byte / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_byte' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for done
    if stats1.errors_done > 0 then
      write(l, string'("Hint: Output 'done' has "));
      write(l, stats1.errors_done);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_done / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'done' has no mismatches."));
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
    if stats1.errors_out_byte > 0 then
      info("Hint: Output 'out_byte' has " & integer'image(stats1.errors_out_byte) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_byte / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_byte' has no mismatches.");
    end if;
    
    if stats1.errors_done > 0 then
      info("Hint: Output 'done' has " & integer'image(stats1.errors_done) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_done / 1 ps) & " ps.");
    else
      info("Hint: Output 'done' has no mismatches.");
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