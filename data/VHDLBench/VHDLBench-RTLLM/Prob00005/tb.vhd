-- VHDL 2008 Testbench for BCD Adder with VUnit Framework
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
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal A : std_logic_vector(3 downto 0) := (others => '0');
  signal B : std_logic_vector(3 downto 0) := (others => '0');
  signal Cin : std_logic := '0';
  signal Sum : std_logic_vector(3 downto 0);
  signal Cout : std_logic;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors          : integer;
    errortime       : time;
    errors_sum      : integer;
    errortime_sum   : time;
    errors_cout     : integer;
    errortime_cout  : time;
    clocks          : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors          => 0,
    errortime       => 0 ps,
    errors_sum      => 0,
    errortime_sum   => 0 ps,
    errors_cout     => 0,
    errortime_cout  => 0 ps,
    clocks          => 0
  );
  
  -- For sharing test case count (use signal instead of shared variable)
  signal case_num_shared : integer := 0;
  constant expected_cases : integer := 100;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    if not sim_done then
      clk <= '0';
      wait for PERIOD / 2;
      clk <= '1';
      wait for PERIOD / 2;
    else
      wait;
    end if;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.adder_bcd
    port map (
      A    => A,
      B    => B,
      Cin  => Cin,
      Sum  => Sum,
      Cout => Cout
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable rand_val : real;
    variable temp_A, temp_B : integer;
    variable temp_Cin : integer;
  begin
    sim_done <= false;
    
    -- Wait one period before starting
    wait for PERIOD;
    
    -- Generate 100 random test cases
    for i in 0 to 99 loop
      -- Generate random A (0-9)
      uniform(seed1, seed2, rand_val);
      temp_A := integer(rand_val * 10.0);
      if temp_A > 9 then
        temp_A := temp_A mod 10;
      end if;
      
      -- Generate random B (0-9)
      uniform(seed1, seed2, rand_val);
      temp_B := integer(rand_val * 10.0);
      if temp_B > 9 then
        temp_B := temp_B mod 10;
      end if;
      
      -- Generate random Cin (0-1)
      uniform(seed1, seed2, rand_val);
      temp_Cin := integer(rand_val * 2.0);
      if temp_Cin > 1 then
        temp_Cin := temp_Cin mod 2;
      end if;
      
      -- Apply inputs
      A <= std_logic_vector(to_unsigned(temp_A, 4));
      B <= std_logic_vector(to_unsigned(temp_B, 4));
      if temp_Cin = 1 then
        Cin <= '1';
      else
        Cin <= '0';
      end if;
      
      -- Wait for operation to complete
      wait for PERIOD;
    end loop;
    
    -- Additional wait period
    wait for PERIOD * 2;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
    variable expected_sum : unsigned(4 downto 0);
    variable A_val, B_val : integer;
    variable Cin_val : integer;
    variable expected_cout : std_logic;
    variable expected_sum_4bit : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Skip first clock (inputs not yet valid)
        if stats1.clocks > 1 then
          -- Calculate expected values
          A_val := to_integer(unsigned(A));
          B_val := to_integer(unsigned(B));
          if Cin = '1' then
            Cin_val := 1;
          else
            Cin_val := 0;
          end if;
          
          expected_sum := to_unsigned(A_val + B_val + Cin_val, 5);
          
          -- Adjust for BCD overflow (sum greater than 9)
          if expected_sum > 9 then
            expected_sum := expected_sum + 6;
          end if;
          
          -- Extract expected Cout and Sum
          expected_cout := expected_sum(4);
          expected_sum_4bit := std_logic_vector(expected_sum(3 downto 0));
          
          -- Verify Sum output
          if Sum /= expected_sum_4bit then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_sum <= stats1.errors_sum + 1;
            
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_sum = 1 then
              stats1.errortime_sum <= now;
            end if;
          end if;
          
          -- Verify Cout output
          if Cout /= expected_cout then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_cout <= stats1.errors_cout + 1;
            
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_cout = 1 then
              stats1.errortime_cout <= now;
            end if;
          end if;
          
          case_num := case_num + 1;
          case_num_shared <= case_num;
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
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_sum > 0 then
      write(l, string'("Hint: Output 'Sum' has "));
      write(l, stats1.errors_sum);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_sum / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Sum' has no mismatches."));
      writeline(f, l);
    end if;
    
    if stats1.errors_cout > 0 then
      write(l, string'("Hint: Output 'Cout' has "));
      write(l, stats1.errors_cout);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_cout / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Cout' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.clocks - 1);  -- Subtract 1 for skipped first clock
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.clocks - 1);
    write(l, string'(" samples"));
    writeline(f, l);
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_sum > 0 then
      info("Hint: Output 'Sum' has " & integer'image(stats1.errors_sum) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_sum / 1 ps) & ".");
    else
      info("Hint: Output 'Sum' has no mismatches.");
    end if;
    
    if stats1.errors_cout > 0 then
      info("Hint: Output 'Cout' has " & integer'image(stats1.errors_cout) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_cout / 1 ps) & ".");
    else
      info("Hint: Output 'Cout' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks - 1) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks - 1) & " samples");
    
    info("========================================");
    
    -- Pass/Fail determination
    if stats1.errors = 0 then
      info("=========== Your Design Passed ===========");
    else
      info("=========== Test completed with " & integer'image(stats1.errors) & 
           " /100 failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;