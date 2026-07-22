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
  -- ========== Constants ==========
  constant PERIOD : time := 10 ns;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(31 downto 0) := (others => '0');
  signal B : std_logic_vector(31 downto 0) := (others => '0');
  signal S : std_logic_vector(31 downto 0);
  signal C32 : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    clocks             => 0
  );
  
  signal test_count_shared : integer := 0;
  
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
  dut1 : entity work.adder_32bit
    port map (
      A   => A,
      B   => B,
      S   => S,
      C32 => C32
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1, seed2 : integer := 42;
    variable rand_val : real;
    variable rand_int : integer;
  begin
    sim_done <= false;
    
    -- Generate 100 random test cases
    for i in 0 to NUM_TESTS - 1 loop
      -- Generate random A
      uniform(seed1, seed2, rand_val);
      rand_int := integer(rand_val * real(2**31));
      A <= std_logic_vector(to_signed(rand_int, 32));
      
      -- Generate random B
      uniform(seed1, seed2, rand_val);
      rand_int := integer(rand_val * real(2**31));
      B <= std_logic_vector(to_signed(rand_int, 32));
      
      -- Wait for result
      wait for PERIOD;
    end loop;
    
    -- Extra time for last result
    wait for PERIOD;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification ==========
  verify_process : process(clk)
    variable test_count : integer := 0;
    variable expected_sum : unsigned(32 downto 0);
    variable A_uns, B_uns : unsigned(31 downto 0);
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Skip first clock (no valid data yet)
        if stats1.clocks > 0 and test_count < NUM_TESTS then
          -- Calculate expected result
          A_uns := unsigned(A);
          B_uns := unsigned(B);
          expected_sum := resize(A_uns, 33) + resize(B_uns, 33);
          
          -- Check S and C32
          if (S /= std_logic_vector(expected_sum(31 downto 0))) or 
             (C32 /= expected_sum(32)) then
            stats1.errors <= stats1.errors + 1;
            
            if stats1.errors = 0 then
              stats1.errortime <= now;
            end if;
          end if;
          
          test_count := test_count + 1;
          test_count_shared <= test_count;
        end if;
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
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 2000 ns;
    
    -- ========== Write to summary.txt ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, NUM_TESTS);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, NUM_TESTS);
    write(l, string'(" samples"));
    writeline(f, l);
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(NUM_TESTS) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(NUM_TESTS) & " samples");
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Test completed with " & 
           integer'image(stats1.errors) & " /100 failures===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;