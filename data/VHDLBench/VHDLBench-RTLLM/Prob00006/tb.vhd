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
  constant PERIOD : time := 4 ns;
  constant DATA_WIDTH : integer := 64;
  constant STG_WIDTH : integer := 16;
  constant NUM_TESTS : integer := 100;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal i_en : std_logic := '0';
  signal adda : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal addb : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal result : std_logic_vector(DATA_WIDTH downto 0);
  signal o_en : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_result      : integer;
    errortime_result   : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_result      => 0,
    errortime_result   => 0 ps,
    clocks             => 0
  );
  
  signal test_count_signal : integer := 0;
  
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
  dut1 : entity work.adder_pipe_64bit
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      STG_WIDTH  => STG_WIDTH
    )
    port map (
      clk    => clk,
      rst_n  => rst_n,
      i_en   => i_en,
      adda   => adda,
      addb   => addb,
      result => result,
      o_en   => o_en
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1, seed2 : positive := 1;
    variable rand_val : real;
    variable temp_a_low, temp_a_high : unsigned(31 downto 0);
    variable temp_b_low, temp_b_high : unsigned(31 downto 0);
  begin
    sim_done <= false;
    
    for test_iter in 0 to NUM_TESTS-1 loop
      rst_n <= '0';
      i_en <= '0';
      
      wait for 8 ns;
      rst_n <= '1';
      
      i_en <= '1';
      
      uniform(seed1, seed2, rand_val);
      temp_a_low := to_unsigned(integer(rand_val * 2147483647.0), 32);
      uniform(seed1, seed2, rand_val);
      temp_a_high := to_unsigned(integer(rand_val * 2147483647.0), 32);
      
      uniform(seed1, seed2, rand_val);
      temp_b_low := to_unsigned(integer(rand_val * 2147483647.0), 32);
      uniform(seed1, seed2, rand_val);
      temp_b_high := to_unsigned(integer(rand_val * 2147483647.0), 32);
      
      adda <= std_logic_vector(temp_a_high & temp_a_low);
      addb <= std_logic_vector(temp_b_high & temp_b_low);
      
      while o_en = '0' loop
        wait until falling_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
    end loop;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification ==========
  verify_process : process(clk)
    variable current_adda : unsigned(DATA_WIDTH-1 downto 0);
    variable current_addb : unsigned(DATA_WIDTH-1 downto 0);
    variable expected : unsigned(DATA_WIDTH downto 0);
  begin
    if falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        if o_en = '1' then
          current_adda := unsigned(adda);
          current_addb := unsigned(addb);
          expected := resize(current_adda, DATA_WIDTH+1) + resize(current_addb, DATA_WIDTH+1);
          
          if unsigned(result) /= expected then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_result <= stats1.errors_result + 1;
            
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_result = 1 then
              stats1.errortime_result <= now;
            end if;
          end if;
          
          test_count_signal <= test_count_signal + 1;
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
    wait for 100000 ns;
    
    -- ========== Write to summary.txt ==========
    if stats1.errors_result > 0 then
      write(l, string'("Hint: Output 'result' has "));
      write(l, stats1.errors_result);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_result / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'result' has no mismatches."));
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
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_result > 0 then
      info("Hint: Output 'result' has " & integer'image(stats1.errors_result) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_result / 1 ps) & ".");
    else
      info("Hint: Output 'result' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & 
           " / " & integer'image(NUM_TESTS) & " failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;