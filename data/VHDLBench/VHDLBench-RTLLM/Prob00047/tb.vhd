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
  constant CLK_PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '1';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal write_en : std_logic := '0';
  signal write_addr : std_logic_vector(7 downto 0) := (others => '0');
  signal write_data : std_logic_vector(5 downto 0) := (others => '0');
  signal read_en : std_logic := '0';
  signal read_addr : std_logic_vector(7 downto 0) := (others => '0');
  signal read_data : std_logic_vector(5 downto 0);
  
  -- Expected value tracking
  signal expected_data : std_logic_vector(5 downto 0) := (others => '0');
  signal check_valid : std_logic := '0';
  signal check_zero : std_logic := '0';
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_read_data   : integer;
    errortime_read_data : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_read_data   => 0,
    errortime_read_data => 0 ps,
    clocks             => 0
  );
  
  -- Test tracking
  signal test_count : integer := 0;
  signal total_tests : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    if not sim_done then
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    else
      wait;
    end if;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.RAM
    port map (
      clk        => clk,
      rst_n      => rst_n,
      write_en   => write_en,
      write_addr => write_addr,
      write_data => write_data,
      read_en    => read_en,
      read_addr  => read_addr,
      read_data  => read_data
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable rand_val : real;
    variable rand_int : integer;
    variable temp_data : std_logic_vector(5 downto 0);
  begin
    sim_done <= false;
    check_valid <= '0';
    check_zero <= '0';
    total_tests <= 0;
    
    -- Repeat 100 times (from Verilog: repeat(100))
    for iter in 0 to 99 loop
      -- Initialize signals
      write_en <= '0';
      write_addr <= (others => '0');
      write_data <= (others => '0');
      read_en <= '0';
      read_addr <= (others => '0');
      
      -- Wait for 5 clock cycles
      wait for CLK_PERIOD * 5;
      
      -- Reset sequence
      rst_n <= '0';
      wait for CLK_PERIOD * 2;
      rst_n <= '1';
      
      -- Write operation
      write_en <= '1';
      write_addr <= (others => '0');  -- Address 0
      
      -- Generate random data (6 bits)
      uniform(seed1, seed2, rand_val);
      rand_int := integer(rand_val * 64.0);  -- 0 to 63 for 6-bit value
      temp_data := std_logic_vector(to_unsigned(rand_int mod 64, 6));
      write_data <= temp_data;
      expected_data <= temp_data;
      
      wait for CLK_PERIOD * 1;
      write_en <= '0';
      wait for CLK_PERIOD * 1;
      
      -- Read operation (should match write_data)
      read_en <= '1';
      read_addr <= (others => '0');  -- Address 0
      wait for CLK_PERIOD * 1;
      check_valid <= '1';
      wait for 1 ps;
      check_valid <= '0';
      total_tests <= total_tests + 1;
      
      -- Read disabled (output should be 0)
      read_en <= '0';
      wait for CLK_PERIOD * 1;
      check_zero <= '1';
      wait for 1 ps;
      check_zero <= '0';
      total_tests <= total_tests + 1;
      
    end loop;
    
    -- End simulation
    wait for CLK_PERIOD * 2;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Process ==========
  verify_process : process(clk)
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check 1: When check_valid is set, read_data should match expected_data
        if check_valid = '1' then
          if read_data /= expected_data then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_read_data <= stats1.errors_read_data + 1;
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_read_data = 1 then
              stats1.errortime_read_data <= now;
            end if;
          end if;
        end if;
        
        -- Check 2: When check_zero is set, read_data should be all zeros
        if check_zero = '1' then
          if read_data /= "000000" then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_read_data <= stats1.errors_read_data + 1;
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_read_data = 1 then
              stats1.errortime_read_data <= now;
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
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for timeout
    wait for 10000000 ps;  -- 10ms should be enough for 100 iterations
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_read_data > 0 then
      write(l, string'("Hint: Output 'read_data' has "));
      write(l, stats1.errors_read_data);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_read_data / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'read_data' has no mismatches."));
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
    
    if stats1.errors_read_data > 0 then
      info("Hint: Output 'read_data' has " & integer'image(stats1.errors_read_data) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_read_data / 1 ps) & ".");
    else
      info("Hint: Output 'read_data' has no mismatches.");
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