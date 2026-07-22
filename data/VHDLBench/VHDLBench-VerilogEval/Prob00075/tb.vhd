-- (2) Testbench (tb entity)
-- Main Testbench for Two-Bit Saturating Counter
-- Verifies DUT against reference implementation
-- Tests asynchronous reset and saturating counter behavior
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
  signal areset      : std_logic := '0';
  signal train_valid : std_logic := '0';
  signal train_taken : std_logic := '0';
  signal state_ref   : std_logic_vector(1 downto 0);
  signal state_dut   : std_logic_vector(1 downto 0);
  
  -- Stimulus control
  signal wavedrom_title            : string(1 to 512);
  signal wavedrom_enable           : std_logic;
  signal wavedrom_hide_after_time  : integer;
  signal sim_done                  : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors            : integer;
    errortime         : time;
    errors_state      : integer;
    errortime_state   : time;
    clocks            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors          => 0,
    errortime       => 0 ps,
    errors_state    => 0,
    errortime_state => 0 ps,
    clocks          => 0
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
      clk                      => clk,
      areset                   => areset,
      train_valid              => train_valid,
      train_taken              => train_taken,
      tb_match                 => tb_match,
      wavedrom_title           => wavedrom_title,
      wavedrom_enable          => wavedrom_enable,
      wavedrom_hide_after_time => wavedrom_hide_after_time,
      sim_done                 => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk         => clk,
      areset      => areset,
      train_valid => train_valid,
      train_taken => train_taken,
      state       => state_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk         => clk,
      areset      => areset,
      train_valid => train_valid,
      train_taken => train_taken,
      state       => state_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Handles 'X' values: X in state_dut only matches X
  -----------------------------------------------------------------------------
  verify_match : process(state_ref, state_dut)
    variable match : boolean;
  begin
    match := true;
    for i in state_ref'range loop
      if state_dut(i) = 'X' or state_dut(i) = 'U' then
        if state_ref(i) /= 'X' and state_ref(i) /= 'U' then
          match := false;
        end if;
      elsif state_ref(i) /= state_dut(i) then
        match := false;
      end if;
    end loop;
    tb_match <= match;
  end process;
  
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
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
        
        -- Check state output specifically
        if state_ref /= state_dut then
          -- Handle X values properly
          if not ((state_dut(0) = 'X' or state_dut(0) = 'U') and 
                  (state_dut(1) = 'X' or state_dut(1) = 'U')) then
            if stats1.errors_state = 0 then
              stats1.errortime_state <= now;
            end if;
            stats1.errors_state <= stats1.errors_state + 1;
          end if;
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
    
    -- Write summary for state output
    if stats1.errors_state > 0 then
      write(l, string'("Hint: Output 'state' has "));
      write(l, stats1.errors_state);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_state / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'state' has no mismatches."));
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
    if stats1.errors_state > 0 then
      info("Hint: Output 'state' has " & integer'image(stats1.errors_state) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_state / 1 ps) & " ps.");
    else
      info("Hint: Output 'state' has no mismatches.");
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