library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  -- ========== Constants ==========
  constant PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal wave : std_logic_vector(4 downto 0);
  
  -- ========== Expected Values ==========
  type reference_array_t is array (0 to 99) of unsigned(4 downto 0);
  
  -- FIXED: Match DUT behavior (hold at peak/trough for 2 cycles)
  function init_reference return reference_array_t is
    variable ref : reference_array_t;
    variable val : integer := 0;
    variable state_var : integer := 0; -- 0=increment, 1=decrement
  begin
    for i in 0 to 99 loop
      ref(i) := to_unsigned(val, 5);
      
      -- Match Verilog DUT logic exactly
      if state_var = 0 then  -- Incrementing
        if val = 31 then
          state_var := 1;  -- Change state, val stays 31 this cycle
        else
          val := val + 1;  -- Increment normally
        end if;
      else  -- Decrementing (state_var = 1)
        if val = 0 then
          state_var := 0;  -- Change state, val stays 0 this cycle
        else
          val := val - 1;  -- Decrement normally
        end if;
      end if;
    end loop;
    return ref;
  end function;
  
  constant expected_results : reference_array_t := init_reference;
  constant expected_cases : integer := 100;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_wave        : integer;
    errortime_wave     : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_wave        => 0,
    errortime_wave     => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '0';
    wait for PERIOD / 2;
    clk <= '1';
    wait for PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.signal_generator
    port map (
      clk   => clk,
      rst_n => rst_n,
      wave  => wave
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: rst_n = 0; #10 rst_n = 1;
    rst_n <= '0';
    wait for 10 ns;
    rst_n <= '1';
    
    -- From: repeat(100) begin ... #10; end
    wait for PERIOD * 100;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check wave against expected value
        if unsigned(wave) /= expected_results(case_num) then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_wave <= stats1.errors_wave + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_wave = 1 then
            stats1.errortime_wave <= now;
          end if;
        end if;
        
        case_num := case_num + 1;
        case_num_shared <= case_num;
      end if;
    end if;
  end process;
  
  -- ========== VUnit Test Runner ==========
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  -- ========== Report Generation ==========
  report_process : process
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- Wait for sim_done
    wait until sim_done;
    wait for PERIOD * 2;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_wave > 0 then
      write(l, string'("Hint: Output 'wave' has "));
      write(l, stats1.errors_wave);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_wave / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'wave' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
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
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_wave > 0 then
      info("Hint: Output 'wave' has " & integer'image(stats1.errors_wave) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_wave / 1 ps) & ".");
    else
      info("Hint: Output 'wave' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;