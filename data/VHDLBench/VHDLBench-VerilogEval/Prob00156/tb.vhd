-- (2) Testbench (tb entity)
-- Main Testbench for Timer FSM
-- Verifies count, counting, and done outputs
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
  signal reset        : std_logic := '0';
  signal data         : std_logic := '0';
  signal ack          : std_logic := '0';
  signal count_ref    : std_logic_vector(3 downto 0);
  signal count_dut    : std_logic_vector(3 downto 0);
  signal counting_ref : std_logic;
  signal counting_dut : std_logic;
  signal done_ref     : std_logic;
  signal done_dut     : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors              : integer;
    errortime           : time;
    errors_count        : integer;
    errortime_count     : time;
    errors_counting     : integer;
    errortime_counting  : time;
    errors_done         : integer;
    errortime_done      : time;
    clocks              : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_count       => 0,
    errortime_count    => 0 ps,
    errors_counting    => 0,
    errortime_counting => 0 ps,
    errors_done        => 0,
    errortime_done     => 0 ps,
    clocks             => 0
  );
  
  -- Verification signals
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
  -- Helper function to check if value is X/U/Z/-
  function is_unknown(val : std_logic) return boolean is
  begin
    return (val = 'U' or val = 'X' or val = 'Z' or val = '-' or val = 'W');
  end function;
  
  -- Helper function to compare with X handling (X in ref matches anything)
  function match_with_x(ref_val, dut_val : std_logic) return boolean is
  begin
    if is_unknown(ref_val) then
      return true;  -- X/U/Z/- in reference matches anything
    elsif is_unknown(dut_val) then
      return is_unknown(ref_val);  -- X in DUT only matches X in ref
    else
      return ref_val = dut_val;
    end if;
  end function;
  
  function match_vec_with_x(ref_val, dut_val : std_logic_vector) return boolean is
  begin
    if ref_val'length /= dut_val'length then
      return false;
    end if;
    for i in ref_val'range loop
      if not match_with_x(ref_val(i), dut_val(i)) then
        return false;
      end if;
    end loop;
    return true;
  end function;
  
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
      clk          => clk,
      reset        => reset,
      data         => data,
      ack          => ack,
      tb_match     => tb_match,
      counting_dut => counting_dut,
      sim_done     => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk      => clk,
      reset    => reset,
      data     => data,
      ack      => ack,
      count    => count_ref,
      counting => counting_ref,
      done     => done_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk      => clk,
      reset    => reset,
      data     => data,
      ack      => ack,
      count    => count_dut,
      counting => counting_dut,
      done     => done_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic (handles X matching like Verilog XOR trick)
  -----------------------------------------------------------------------------
  tb_match <= match_vec_with_x(count_ref, count_dut) and
              match_with_x(counting_ref, counting_dut) and
              match_with_x(done_ref, done_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- CRITICAL: Only count when sim_done = false
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Overall match check
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Check count output
        if not match_vec_with_x(count_ref, count_dut) then
          if stats1.errors_count = 0 then
            stats1.errortime_count <= now;
          end if;
          stats1.errors_count <= stats1.errors_count + 1;
        end if;
        
        -- Check counting output
        if not match_with_x(counting_ref, counting_dut) then
          if stats1.errors_counting = 0 then
            stats1.errortime_counting <= now;
          end if;
          stats1.errors_counting <= stats1.errors_counting + 1;
        end if;
        
        -- Check done output
        if not match_with_x(done_ref, done_dut) then
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
  -- CRITICAL: Wait for sim_done, NOT fixed delay!
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- CRITICAL: Wait for stimulus completion
    wait until sim_done;
    wait for 100 ps;  -- Allow final statistics to settle
    
    -- Write summary for count
    if stats1.errors_count > 0 then
      write(l, string'("Hint: Output 'count' has "));
      write(l, stats1.errors_count);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_count / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'count' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for counting
    if stats1.errors_counting > 0 then
      write(l, string'("Hint: Output 'counting' has "));
      write(l, stats1.errors_counting);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_counting / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'counting' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for done
    if stats1.errors_done > 0 then
      write(l, string'("Hint: Output 'done' has "));
      write(l, stats1.errors_done);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_done / 1 ps);
      write(l, string'("."));
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
    if stats1.errors_count > 0 then
      info("Hint: Output 'count' has " & integer'image(stats1.errors_count) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_count / 1 ps) & ".");
    else
      info("Hint: Output 'count' has no mismatches.");
    end if;
    
    if stats1.errors_counting > 0 then
      info("Hint: Output 'counting' has " & integer'image(stats1.errors_counting) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_counting / 1 ps) & ".");
    else
      info("Hint: Output 'counting' has no mismatches.");
    end if;
    
    if stats1.errors_done > 0 then
      info("Hint: Output 'done' has " & integer'image(stats1.errors_done) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_done / 1 ps) & ".");
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