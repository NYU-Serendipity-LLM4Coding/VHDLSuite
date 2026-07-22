-- (2) Testbench (tb entity)
-- Main Testbench for PS/2 Scancode Decoder
-- Verifies left, down, right, up outputs
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
  signal scancode   : std_logic_vector(15 downto 0) := x"0000";
  signal left_ref   : std_logic;
  signal left_dut   : std_logic;
  signal down_ref   : std_logic;
  signal down_dut   : std_logic;
  signal right_ref  : std_logic;
  signal right_dut  : std_logic;
  signal up_ref     : std_logic;
  signal up_dut     : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for four outputs)
  type stats_t is record
    errors            : integer;
    errortime         : time;
    errors_left       : integer;
    errortime_left    : time;
    errors_down       : integer;
    errortime_down    : time;
    errors_right      : integer;
    errortime_right   : time;
    errors_up         : integer;
    errortime_up      : time;
    clocks            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors         => 0,
    errortime      => 0 ps,
    errors_left    => 0,
    errortime_left => 0 ps,
    errors_down    => 0,
    errortime_down => 0 ps,
    errors_right   => 0,
    errortime_right => 0 ps,
    errors_up      => 0,
    errortime_up   => 0 ps,
    clocks         => 0
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
      scancode        => scancode,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      scancode => scancode,
      left     => left_ref,
      down     => down_ref,
      right    => right_ref,
      up       => up_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      scancode => scancode,
      left     => left_dut,
      down     => down_dut,
      right    => right_dut,
      up       => up_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (left_ref = left_dut) and 
              (down_ref = down_dut) and 
              (right_ref = right_dut) and 
              (up_ref = up_dut);
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
        
        -- Check left output
        if left_ref /= left_dut then
          if stats1.errors_left = 0 then
            stats1.errortime_left <= now;
          end if;
          stats1.errors_left <= stats1.errors_left + 1;
        end if;
        
        -- Check down output
        if down_ref /= down_dut then
          if stats1.errors_down = 0 then
            stats1.errortime_down <= now;
          end if;
          stats1.errors_down <= stats1.errors_down + 1;
        end if;
        
        -- Check right output
        if right_ref /= right_dut then
          if stats1.errors_right = 0 then
            stats1.errortime_right <= now;
          end if;
          stats1.errors_right <= stats1.errors_right + 1;
        end if;
        
        -- Check up output
        if up_ref /= up_dut then
          if stats1.errors_up = 0 then
            stats1.errortime_up <= now;
          end if;
          stats1.errors_up <= stats1.errors_up + 1;
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
    
    -- Write summary for left
    if stats1.errors_left > 0 then
      write(l, string'("Hint: Output 'left' has "));
      write(l, stats1.errors_left);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_left / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'left' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for down
    if stats1.errors_down > 0 then
      write(l, string'("Hint: Output 'down' has "));
      write(l, stats1.errors_down);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_down / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'down' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for right
    if stats1.errors_right > 0 then
      write(l, string'("Hint: Output 'right' has "));
      write(l, stats1.errors_right);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_right / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'right' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for up
    if stats1.errors_up > 0 then
      write(l, string'("Hint: Output 'up' has "));
      write(l, stats1.errors_up);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_up / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'up' has no mismatches."));
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
    if stats1.errors_left > 0 then
      info("Hint: Output 'left' has " & integer'image(stats1.errors_left) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_left / 1 ps) & " ps.");
    else
      info("Hint: Output 'left' has no mismatches.");
    end if;
    
    if stats1.errors_down > 0 then
      info("Hint: Output 'down' has " & integer'image(stats1.errors_down) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_down / 1 ps) & " ps.");
    else
      info("Hint: Output 'down' has no mismatches.");
    end if;
    
    if stats1.errors_right > 0 then
      info("Hint: Output 'right' has " & integer'image(stats1.errors_right) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_right / 1 ps) & " ps.");
    else
      info("Hint: Output 'right' has no mismatches.");
    end if;
    
    if stats1.errors_up > 0 then
      info("Hint: Output 'up' has " & integer'image(stats1.errors_up) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_up / 1 ps) & " ps.");
    else
      info("Hint: Output 'up' has no mismatches.");
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