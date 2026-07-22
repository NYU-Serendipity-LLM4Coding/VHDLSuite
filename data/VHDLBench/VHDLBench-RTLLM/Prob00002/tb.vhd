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
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(15 downto 0) := (others => '0');
  signal b : std_logic_vector(15 downto 0) := (others => '0');
  signal Cin : std_logic := '0';
  signal y : std_logic_vector(15 downto 0);
  signal Co : std_logic;
  
  -- Reference calculation signals
  signal tb_sum : unsigned(16 downto 0);
  signal tb_co : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_y           : integer;
    errortime_y        : time;
    errors_Co          : integer;
    errortime_Co       : time;
    samples            : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_y           => 0,
    errortime_y        => 0 ps,
    errors_Co          => 0,
    errortime_Co       => 0 ps,
    samples            => 0
  );
  
  -- Test counter (signal instead of shared variable)
  signal test_count : integer := 0;
  constant expected_tests : integer := 100;
  
  -- LFSR for random number generation
  function lfsr_next(current : unsigned) return unsigned is
    variable feedback : std_logic;
    variable result : unsigned(31 downto 0);
  begin
    result := current;
    feedback := result(31) xor result(21) xor result(1) xor result(0);
    result := feedback & result(31 downto 1);
    return result;
  end function;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.adder_16bit
    port map (
      a   => a,
      b   => b,
      Cin => Cin,
      y   => y,
      Co  => Co
    );
  
  -- ========== Reference Calculation ==========
  tb_sum <= resize(unsigned(a), 17) + resize(unsigned(b), 17);
  tb_co <= tb_sum(16);
  
  -- ========== Stimulus and Verification ==========
  stimulus_process : process
    variable seed : unsigned(31 downto 0) := x"12345678";
    variable error_y : boolean;
    variable error_Co : boolean;
  begin
    sim_done <= false;
    
    -- Run 100 test iterations
    for i in 0 to 99 loop
      -- Generate random values using LFSR
      seed := lfsr_next(seed);
      a <= std_logic_vector(seed(15 downto 0));
      
      seed := lfsr_next(seed);
      b <= std_logic_vector(seed(15 downto 0));
      
      Cin <= '0';
      
      -- Wait for combinational logic to settle
      wait for PERIOD;
      
      -- Increment sample counter
      stats1.samples <= stats1.samples + 1;
      test_count <= i + 1;
      
      -- Check outputs
      error_y := false;
      error_Co := false;
      
      if y /= std_logic_vector(tb_sum(15 downto 0)) then
        error_y := true;
        stats1.errors_y <= stats1.errors_y + 1;
        if stats1.errors_y = 0 then
          stats1.errortime_y <= now;
        end if;
      end if;
      
      if Co /= tb_co then
        error_Co := true;
        stats1.errors_Co <= stats1.errors_Co + 1;
        if stats1.errors_Co = 0 then
          stats1.errortime_Co <= now;
        end if;
      end if;
      
      if error_y or error_Co then
        stats1.errors <= stats1.errors + 1;
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
      end if;
      
    end loop;
    
    -- End simulation
    sim_done <= true;
    wait;
  end process;
  
  -- ========== VUnit Test Runner ==========
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  -- ========== Report Generation ==========
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for simulation to complete
    wait until sim_done;
    wait for 100 ns;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_y > 0 then
      write(l, string'("Hint: Output 'y' has "));
      write(l, stats1.errors_y);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_y / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'y' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_Co > 0 then
      write(l, string'("Hint: Output 'Co' has "));
      write(l, stats1.errors_Co);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Co / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Co' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.samples);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.samples);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_y > 0 then
      info("Hint: Output 'y' has " & integer'image(stats1.errors_y) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_y / 1 ps) & ".");
    else
      info("Hint: Output 'y' has no mismatches.");
    end if;
    
    if stats1.errors_Co > 0 then
      info("Hint: Output 'Co' has " & integer'image(stats1.errors_Co) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_Co / 1 ps) & ".");
    else
      info("Hint: Output 'Co' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.samples) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.samples) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & integer'image(stats1.errors) & 
           " / 100 failures===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;