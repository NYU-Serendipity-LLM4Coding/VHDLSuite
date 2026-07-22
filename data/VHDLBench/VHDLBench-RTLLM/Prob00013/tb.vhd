-- (1) Testbench with integrated stimulus (tb entity)
-- VUnit framework + stimulus generation + verification against expected values
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
  constant WIDTH : integer := 8;
  
  -- ========== Signals ==========
  signal clk : std_logic := '1';
  signal reset : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal b : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal p : std_logic_vector(2*WIDTH-1 downto 0);
  signal rdy : std_logic;
  
  -- Test control
  signal check_result : boolean := false;
  signal expected_p : signed(2*WIDTH-1 downto 0) := (others => '0');
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_p           : integer;
    errortime_p        : time;
    clocks             : integer;
    total_tests        : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_p           => 0,
    errortime_p        => 0 ps,
    clocks             => 0,
    total_tests        => 0
  );
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '1';
    wait for PERIOD / 2;
    clk <= '0';
    wait for PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.multi_booth_8bit
    port map (
      clk   => clk,
      reset => reset,
      a     => a,
      b     => b,
      p     => p,
      rdy   => rdy
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    file fp : text;
    variable l : line;
    variable a_int, b_int : integer;
    variable numtests : integer;
    variable good_read : boolean;
    variable file_status : file_open_status;
    variable char_temp : character;
  begin
    sim_done <= false;
    check_result <= false;
    
    -- Try to open test data file
    file_open(file_status, fp, "test_data.dat", read_mode);
    
    if file_status /= open_ok then
      -- File doesn't exist, run default test cases
      info("test_data.dat not found, using default test cases");
      numtests := 10;
      
      -- Default test cases
      for i in 0 to numtests-1 loop
        case i is
          when 0 => a_int := 5; b_int := 3;
          when 1 => a_int := -5; b_int := 3;
          when 2 => a_int := 5; b_int := -3;
          when 3 => a_int := -5; b_int := -3;
          when 4 => a_int := 127; b_int := 1;
          when 5 => a_int := -128; b_int := 1;
          when 6 => a_int := 15; b_int := 15;
          when 7 => a_int := 0; b_int := 100;
          when 8 => a_int := 100; b_int := 0;
          when others => a_int := 10; b_int := 10;
        end case;
        
        -- Set inputs
        a <= std_logic_vector(to_signed(a_int, WIDTH));
        b <= std_logic_vector(to_signed(b_int, WIDTH));
        
        -- Calculate expected result
        expected_p <= to_signed(a_int, WIDTH) * to_signed(b_int, WIDTH);
        
        -- Reset for one clock cycle
        reset <= '1';
        wait until rising_edge(clk);
        
        -- Remove reset
        wait for 1 ns;
        reset <= '0';
        
        -- Wait for ready signal
        while rdy = '0' loop
          wait until rising_edge(clk);
        end loop;
        
        -- Signal to verify process to check result
        wait until rising_edge(clk);
        check_result <= true;
        wait until rising_edge(clk);
        check_result <= false;
        
        stats1.total_tests <= i + 1;
      end loop;
      
    else
      -- File exists, read test vectors
      if not endfile(fp) then
        readline(fp, l);
        read(l, numtests, good_read);
        if not good_read then
          numtests := 0;
        end if;
      else
        numtests := 0;
      end if;
      
      -- Run through all test vectors from file
      for i in 0 to numtests-1 loop
        if endfile(fp) then
          exit;
        end if;
        
        -- Read test vector
        readline(fp, l);
        read(l, a_int, good_read);
        if good_read then
          -- Skip whitespace
          while l'length > 0 loop
            read(l, char_temp, good_read);
            exit when not good_read or char_temp /= ' ';
          end loop;
          if good_read and char_temp /= ' ' then
            -- Put back non-space character
            -- Read b_int directly
            read(l, b_int, good_read);
          end if;
        end if;
        
        if not good_read then
          exit;
        end if;
        
        -- Set inputs
        a <= std_logic_vector(to_signed(a_int, WIDTH));
        b <= std_logic_vector(to_signed(b_int, WIDTH));
        
        -- Calculate expected result
        expected_p <= to_signed(a_int, WIDTH) * to_signed(b_int, WIDTH);
        
        -- Reset for one clock cycle
        reset <= '1';
        wait until rising_edge(clk);
        
        -- Remove reset
        wait for 1 ns;
        reset <= '0';
        
        -- Wait for ready signal
        while rdy = '0' loop
          wait until rising_edge(clk);
        end loop;
        
        -- Signal to verify process to check result
        wait until rising_edge(clk);
        check_result <= true;
        wait until rising_edge(clk);
        check_result <= false;
        
        stats1.total_tests <= i + 1;
      end loop;
      
      file_close(fp);
    end if;
    
    wait for PERIOD * 2;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Process ==========
  verify_process : process(clk)
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check result when signaled
        if check_result then
          if signed(p) /= expected_p then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_p <= stats1.errors_p + 1;
            
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_p = 1 then
              stats1.errortime_p <= now;
            end if;
          end if;
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- Wait for simulation to complete
    wait until sim_done;
    wait for PERIOD * 2;
    
    -- Open summary file
    file_open(file_status, f, "summary.txt", write_mode);
    
    -- ========== Write to summary.txt ==========
    if stats1.errors_p > 0 then
      write(l, string'("Hint: Output 'p' has "));
      write(l, stats1.errors_p);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_p / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'p' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.total_tests);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.total_tests);
    write(l, string'(" samples"));
    writeline(f, l);
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_p > 0 then
      info("Hint: Output 'p' has " & integer'image(stats1.errors_p) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_p / 1 ps) & ".");
    else
      info("Hint: Output 'p' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.total_tests) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.total_tests) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and stats1.total_tests > 0 then
      info("===========Your Design Passed===========");
    else
      info("=========== Failed ===========");
      if stats1.total_tests = 0 then
        check_failed("Test failed: No test cases executed");
      else
        check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
      end if;
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;