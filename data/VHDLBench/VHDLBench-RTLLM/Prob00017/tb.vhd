-- (1) Testbench with integrated stimulus (tb entity)
-- VUnit framework + stimulus generation + verification against expected values
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  -- ========== Constants (from Verilog parameters) ==========
  constant Q : integer := 15;
  constant N : integer := 32;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(N-1 downto 0) := (others => '0');
  signal b : std_logic_vector(N-1 downto 0) := (others => '0');
  signal c : std_logic_vector(N-1 downto 0);
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_c           : integer;
    errortime_c        : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_c           => 0,
    errortime_c        => 0 ps,
    clocks             => 0
  );
  
  signal test_num_shared : integer := 0;
  
  -- Function to calculate expected result (from testbench logic)
  function calc_expected(a_val, b_val : std_logic_vector(N-1 downto 0)) return std_logic_vector is
    variable result : std_logic_vector(N-1 downto 0);
    variable a_unsigned : unsigned(N-2 downto 0);
    variable b_unsigned : unsigned(N-2 downto 0);
    variable sum_result : unsigned(N-2 downto 0);
  begin
    a_unsigned := unsigned(a_val(N-2 downto 0));
    b_unsigned := unsigned(b_val(N-2 downto 0));
    
    -- Same sign
    if a_val(N-1) = b_val(N-1) then
      result(N-2 downto 0) := std_logic_vector(unsigned(a_val(N-2 downto 0)) - unsigned(b_val(N-2 downto 0)));
      result(N-1) := a_val(N-1);
    -- a positive, b negative
    elsif a_val(N-1) = '0' and b_val(N-1) = '1' then
      if a_unsigned > b_unsigned then
        result(N-2 downto 0) := std_logic_vector(a_unsigned + b_unsigned);
        result(N-1) := '0';
      else
        sum_result := b_unsigned + a_unsigned;
        result(N-2 downto 0) := std_logic_vector(sum_result);
        if sum_result = 0 then
          result(N-1) := '0';
        else
          result(N-1) := '1';
        end if;
      end if;
    -- a negative, b positive
    else
      if a_unsigned > b_unsigned then
        sum_result := a_unsigned + b_unsigned;
        result(N-2 downto 0) := std_logic_vector(sum_result);
        if sum_result = 0 then
          result(N-1) := '0';
        else
          result(N-1) := '1';
        end if;
      else
        result(N-2 downto 0) := std_logic_vector(b_unsigned + a_unsigned);
        result(N-1) := '0';
      end if;
    end if;
    
    return result;
  end function;
  
begin

  -- ========== Clock Generation (for timing reference) ==========
  clk_process : process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.fixed_point_subtractor
    generic map (
      Q => Q,
      N => N
    )
    port map (
      a => a,
      b => b,
      c => c
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable expected_result : std_logic_vector(N-1 downto 0);
    variable seed1 : positive := 12345;
    variable seed2 : positive := 67890;
    variable rand_val : real;
    variable a_temp : std_logic_vector(N-1 downto 0);
    variable b_temp : std_logic_vector(N-1 downto 0);
  begin
    sim_done <= false;
    
    -- Run 100 random test cases
    for i in 0 to NUM_TESTS-1 loop
      -- Generate random inputs using uniform function
      for j in 0 to N-1 loop
        uniform(seed1, seed2, rand_val);
        if rand_val > 0.5 then
          a_temp(j) := '1';
        else
          a_temp(j) := '0';
        end if;
        
        uniform(seed1, seed2, rand_val);
        if rand_val > 0.5 then
          b_temp(j) := '1';
        else
          b_temp(j) := '0';
        end if;
      end loop;
      
      a <= a_temp;
      b <= b_temp;
      
      -- Wait for combinational logic to settle
      wait for 10 ns;
      
      -- Calculate expected result
      expected_result := calc_expected(a_temp, b_temp);
      
      -- Check result
      if c /= expected_result then
        stats1.errors <= stats1.errors + 1;
        stats1.errors_c <= stats1.errors_c + 1;
        
        if stats1.errors = 1 then
          stats1.errortime <= now;
        end if;
        if stats1.errors_c = 1 then
          stats1.errortime_c <= now;
        end if;
      end if;
      
      stats1.clocks <= stats1.clocks + 1;
      test_num_shared <= i + 1;
      
    end loop;
    
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
    if stats1.errors_c > 0 then
      write(l, string'("Hint: Output 'c' has "));
      write(l, stats1.errors_c);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_c / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'c' has no mismatches."));
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
    
    -- ========== Console Output (mirror file) ==========
    info("========================================");
    
    if stats1.errors_c > 0 then
      info("Hint: Output 'c' has " & integer'image(stats1.errors_c) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_c / 1 ps) & ".");
    else
      info("Hint: Output 'c' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & 
           " /100 failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;