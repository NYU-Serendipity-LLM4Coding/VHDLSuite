-- (2) Testbench (tb entity)
-- Main Testbench for Moore State Machine Next-State Logic
-- Verifies 8 outputs: B3_next, S_next, S1_next, Count_next, Wait_next, done, counting, shift_ena
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
  signal d             : std_logic := '0';
  signal done_counting : std_logic := '0';
  signal ack           : std_logic := '0';
  signal state         : std_logic_vector(9 downto 0) := (others => '0');
  
  -- Output signals (reference)
  signal B3_next_ref    : std_logic;
  signal S_next_ref     : std_logic;
  signal S1_next_ref    : std_logic;
  signal Count_next_ref : std_logic;
  signal Wait_next_ref  : std_logic;
  signal done_ref       : std_logic;
  signal counting_ref   : std_logic;
  signal shift_ena_ref  : std_logic;
  
  -- Output signals (DUT)
  signal B3_next_dut    : std_logic;
  signal S_next_dut     : std_logic;
  signal S1_next_dut    : std_logic;
  signal Count_next_dut : std_logic;
  signal Wait_next_dut  : std_logic;
  signal done_dut       : std_logic;
  signal counting_dut   : std_logic;
  signal shift_ena_dut  : std_logic;
  
  -- Control
  signal sim_done : boolean := false;
  
  -- Statistics type
  type stats_t is record
    errors                 : integer;
    errortime              : time;
    errors_B3_next         : integer;
    errortime_B3_next      : time;
    errors_S_next          : integer;
    errortime_S_next       : time;
    errors_S1_next         : integer;
    errortime_S1_next      : time;
    errors_Count_next      : integer;
    errortime_Count_next   : time;
    errors_Wait_next       : integer;
    errortime_Wait_next    : time;
    errors_done            : integer;
    errortime_done         : time;
    errors_counting        : integer;
    errortime_counting     : time;
    errors_shift_ena       : integer;
    errortime_shift_ena    : time;
    clocks                 : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors               => 0,
    errortime            => 0 ps,
    errors_B3_next       => 0,
    errortime_B3_next    => 0 ps,
    errors_S_next        => 0,
    errortime_S_next     => 0 ps,
    errors_S1_next       => 0,
    errortime_S1_next    => 0 ps,
    errors_Count_next    => 0,
    errortime_Count_next => 0 ps,
    errors_Wait_next     => 0,
    errortime_Wait_next  => 0 ps,
    errors_done          => 0,
    errortime_done       => 0 ps,
    errors_counting      => 0,
    errortime_counting   => 0 ps,
    errors_shift_ena     => 0,
    errortime_shift_ena  => 0 ps,
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
      clk           => clk,
      d             => d,
      done_counting => done_counting,
      ack           => ack,
      state         => state,
      tb_match      => tb_match,
      sim_done      => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      d             => d,
      done_counting => done_counting,
      ack           => ack,
      state         => state,
      B3_next       => B3_next_ref,
      S_next        => S_next_ref,
      S1_next       => S1_next_ref,
      Count_next    => Count_next_ref,
      Wait_next     => Wait_next_ref,
      done          => done_ref,
      counting      => counting_ref,
      shift_ena     => shift_ena_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      d             => d,
      done_counting => done_counting,
      ack           => ack,
      state         => state,
      B3_next       => B3_next_dut,
      S_next        => S_next_dut,
      S1_next       => S1_next_dut,
      Count_next    => Count_next_dut,
      Wait_next     => Wait_next_dut,
      done          => done_dut,
      counting      => counting_dut,
      shift_ena     => shift_ena_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (B3_next_ref = B3_next_dut) and
              (S_next_ref = S_next_dut) and
              (S1_next_ref = S1_next_dut) and
              (Count_next_ref = Count_next_dut) and
              (Wait_next_ref = Wait_next_dut) and
              (done_ref = done_dut) and
              (counting_ref = counting_dut) and
              (shift_ena_ref = shift_ena_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Overall match
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Individual output checks
        if B3_next_ref /= B3_next_dut then
          if stats1.errors_B3_next = 0 then
            stats1.errortime_B3_next <= now;
          end if;
          stats1.errors_B3_next <= stats1.errors_B3_next + 1;
        end if;
        
        if S_next_ref /= S_next_dut then
          if stats1.errors_S_next = 0 then
            stats1.errortime_S_next <= now;
          end if;
          stats1.errors_S_next <= stats1.errors_S_next + 1;
        end if;
        
        if S1_next_ref /= S1_next_dut then
          if stats1.errors_S1_next = 0 then
            stats1.errortime_S1_next <= now;
          end if;
          stats1.errors_S1_next <= stats1.errors_S1_next + 1;
        end if;
        
        if Count_next_ref /= Count_next_dut then
          if stats1.errors_Count_next = 0 then
            stats1.errortime_Count_next <= now;
          end if;
          stats1.errors_Count_next <= stats1.errors_Count_next + 1;
        end if;
        
        if Wait_next_ref /= Wait_next_dut then
          if stats1.errors_Wait_next = 0 then
            stats1.errortime_Wait_next <= now;
          end if;
          stats1.errors_Wait_next <= stats1.errors_Wait_next + 1;
        end if;
        
        if done_ref /= done_dut then
          if stats1.errors_done = 0 then
            stats1.errortime_done <= now;
          end if;
          stats1.errors_done <= stats1.errors_done + 1;
        end if;
        
        if counting_ref /= counting_dut then
          if stats1.errors_counting = 0 then
            stats1.errortime_counting <= now;
          end if;
          stats1.errors_counting <= stats1.errors_counting + 1;
        end if;
        
        if shift_ena_ref /= shift_ena_dut then
          if stats1.errors_shift_ena = 0 then
            stats1.errortime_shift_ena <= now;
          end if;
          stats1.errors_shift_ena <= stats1.errors_shift_ena + 1;
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
    if stats1.errors_B3_next > 0 then
      write(l, string'("Hint: Output 'B3_next' has "));
      write(l, stats1.errors_B3_next);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_B3_next / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'B3_next' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_S_next > 0 then
      write(l, string'("Hint: Output 'S_next' has "));
      write(l, stats1.errors_S_next);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_S_next / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'S_next' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_S1_next > 0 then
      write(l, string'("Hint: Output 'S1_next' has "));
      write(l, stats1.errors_S1_next);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_S1_next / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'S1_next' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_Count_next > 0 then
      write(l, string'("Hint: Output 'Count_next' has "));
      write(l, stats1.errors_Count_next);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Count_next / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Count_next' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_Wait_next > 0 then
      write(l, string'("Hint: Output 'Wait_next' has "));
      write(l, stats1.errors_Wait_next);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Wait_next / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Wait_next' has no mismatches."));
      writeline(f, l);
    end if;
    
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
    
    if stats1.errors_counting > 0 then
      write(l, string'("Hint: Output 'counting' has "));
      write(l, stats1.errors_counting);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_counting / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'counting' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_shift_ena > 0 then
      write(l, string'("Hint: Output 'shift_ena' has "));
      write(l, stats1.errors_shift_ena);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_shift_ena / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'shift_ena' has no mismatches."));
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
    info("Output B3_next: " & integer'image(stats1.errors_B3_next) & " mismatches");
    info("Output S_next: " & integer'image(stats1.errors_S_next) & " mismatches");
    info("Output S1_next: " & integer'image(stats1.errors_S1_next) & " mismatches");
    info("Output Count_next: " & integer'image(stats1.errors_Count_next) & " mismatches");
    info("Output Wait_next: " & integer'image(stats1.errors_Wait_next) & " mismatches");
    info("Output done: " & integer'image(stats1.errors_done) & " mismatches");
    info("Output counting: " & integer'image(stats1.errors_counting) & " mismatches");
    info("Output shift_ena: " & integer'image(stats1.errors_shift_ena) & " mismatches");
    info("Total: " & integer'image(stats1.errors) & " / " & integer'image(stats1.clocks));
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & " mismatches");
    else
      info("PASS: All samples matched!");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;