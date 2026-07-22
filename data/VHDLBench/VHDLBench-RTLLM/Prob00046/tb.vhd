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
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(31 downto 0) := (others => '0');
  signal b : std_logic_vector(31 downto 0) := (others => '0');
  signal c : std_logic_vector(31 downto 0);
  
  -- ========== Expected Values ==========
  -- Expected final result: 0 + (1*1) + (2*2) + (3*3) = 0 + 1 + 4 + 9 = 14 (0x0e)
  constant expected_final : unsigned(31 downto 0) := to_unsigned(14, 32);
  
  -- ========== Statistics ==========
  type stats_t is record
    errors          : integer;
    errortime       : time;
    errors_c        : integer;
    errortime_c     : time;
    clocks          : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors          => 0,
    errortime       => 0 ps,
    errors_c        => 0,
    errortime_c     => 0 ps,
    clocks          => 0
  );
  
  signal final_c_value : std_logic_vector(31 downto 0) := (others => '0');
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.pe
    port map (
      clk => clk,
      rst => rst,
      a   => a,
      b   => b,
      c   => c
    );
  
  -- ========== Stimulus Generation (from Verilog initial block) ==========
  -- Manual clock control matching the Verilog testbench exactly
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial values: a=0; b=0; clk=0; rst=1;
    a <= (others => '0');
    b <= (others => '0');
    clk <= '0';
    rst <= '1';
    
    -- #5; clk=1;
    wait for 5 ns;
    clk <= '1';
    
    -- #5; clk=0; rst=0;
    wait for 5 ns;
    clk <= '0';
    rst <= '0';
    
    -- #5;
    wait for 5 ns;
    
    -- a=1; b=1; #5; clk=1; #5; clk=0;
    a <= std_logic_vector(to_unsigned(1, 32));
    b <= std_logic_vector(to_unsigned(1, 32));
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    
    -- a=2; b=2; #5; clk=1; #5; clk=0;
    a <= std_logic_vector(to_unsigned(2, 32));
    b <= std_logic_vector(to_unsigned(2, 32));
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    
    -- a=3; b=3; #5; clk=1; #5; clk=0;
    a <= std_logic_vector(to_unsigned(3, 32));
    b <= std_logic_vector(to_unsigned(3, 32));
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    
    -- Capture final value
    wait for 1 ns;
    final_c_value <= c;
    
    -- Wait before ending
    wait for 10 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
  begin
    wait until sim_done;
    wait for 1 ns;
    
    -- Check final result
    if unsigned(final_c_value) /= expected_final then
      stats1.errors <= 1;
      stats1.errors_c <= 1;
      stats1.errortime <= now;
      stats1.errortime_c <= now;
    end if;
    
    stats1.clocks <= 1;
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
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    -- Wait for simulation to complete
    wait until sim_done;
    wait for 10 ns;
    
    -- Open file
    file_open(file_status, f, "summary.txt", write_mode);
    
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
    
    -- ========== Pass/Fail (from Verilog) ==========
    if unsigned(final_c_value) = expected_final then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      info("Final result c = 0x" & to_hstring(unsigned(final_c_value)) & 
           ", expected 0x0000000e");
      check_failed("Test failed");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;