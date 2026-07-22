-- (2) Testbench (tb entity)
-- Main Testbench for Vector Concatenation
-- Verifies w, x, y, z outputs
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
  
  -- Input signals
  signal a : std_logic_vector(4 downto 0) := (others => '0');
  signal b : std_logic_vector(4 downto 0) := (others => '0');
  signal c : std_logic_vector(4 downto 0) := (others => '0');
  signal d : std_logic_vector(4 downto 0) := (others => '0');
  signal e : std_logic_vector(4 downto 0) := (others => '0');
  signal f : std_logic_vector(4 downto 0) := (others => '0');
  
  -- Output signals
  signal w_ref : std_logic_vector(7 downto 0);
  signal w_dut : std_logic_vector(7 downto 0);
  signal x_ref : std_logic_vector(7 downto 0);
  signal x_dut : std_logic_vector(7 downto 0);
  signal y_ref : std_logic_vector(7 downto 0);
  signal y_dut : std_logic_vector(7 downto 0);
  signal z_ref : std_logic_vector(7 downto 0);
  signal z_dut : std_logic_vector(7 downto 0);
  
  -- Control signals
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for four outputs)
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_w       : integer;
    errortime_w    : time;
    errors_x       : integer;
    errortime_x    : time;
    errors_y       : integer;
    errortime_y    : time;
    errors_z       : integer;
    errortime_z    : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors       => 0,
    errortime    => 0 ps,
    errors_w     => 0,
    errortime_w  => 0 ps,
    errors_x     => 0,
    errortime_x  => 0 ps,
    errors_y     => 0,
    errortime_y  => 0 ps,
    errors_z     => 0,
    errortime_z  => 0 ps,
    clocks       => 0
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
      a               => a,
      b               => b,
      c               => c,
      d               => d,
      e               => e,
      f               => f,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      a => a,
      b => b,
      c => c,
      d => d,
      e => e,
      f => f,
      w => w_ref,
      x => x_ref,
      y => y_ref,
      z => z_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      a => a,
      b => b,
      c => c,
      d => d,
      e => e,
      f => f,
      w => w_dut,
      x => x_dut,
      y => y_dut,
      z => z_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ w_ref, x_ref, y_ref, z_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (w_ref = w_dut) and (x_ref = x_dut) and 
              (y_ref = y_dut) and (z_ref = z_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -- CRITICAL: Only count when not sim_done to prevent extra mismatches
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
        
        -- Check w
        if w_ref /= w_dut then
          if stats1.errors_w = 0 then
            stats1.errortime_w <= now;
          end if;
          stats1.errors_w <= stats1.errors_w + 1;
        end if;
        
        -- Check x
        if x_ref /= x_dut then
          if stats1.errors_x = 0 then
            stats1.errortime_x <= now;
          end if;
          stats1.errors_x <= stats1.errors_x + 1;
        end if;
        
        -- Check y
        if y_ref /= y_dut then
          if stats1.errors_y = 0 then
            stats1.errortime_y <= now;
          end if;
          stats1.errors_y <= stats1.errors_y + 1;
        end if;
        
        -- Check z
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
    wait for 1000000 ps;
    
    -- Write summary for w
    if stats1.errors_w > 0 then
      write(l, string'("Hint: Output 'w' has "));
      write(l, stats1.errors_w);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_w / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'w' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for x
    if stats1.errors_x > 0 then
      write(l, string'("Hint: Output 'x' has "));
      write(l, stats1.errors_x);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_x / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'x' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for y
    if stats1.errors_y > 0 then
      write(l, string'("Hint: Output 'y' has "));
      write(l, stats1.errors_y);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_y / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'y' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for z
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
    if stats1.errors_w > 0 then
      info("Hint: Output 'w' has " & integer'image(stats1.errors_w) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_w / 1 ps) & " ps.");
    else
      info("Hint: Output 'w' has no mismatches.");
    end if;
    
    if stats1.errors_x > 0 then
      info("Hint: Output 'x' has " & integer'image(stats1.errors_x) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_x / 1 ps) & " ps.");
    else
      info("Hint: Output 'x' has no mismatches.");
    end if;
    
    if stats1.errors_y > 0 then
      info("Hint: Output 'y' has " & integer'image(stats1.errors_y) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_y / 1 ps) & " ps.");
    else
      info("Hint: Output 'y' has no mismatches.");
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