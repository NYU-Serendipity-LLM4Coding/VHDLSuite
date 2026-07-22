-- VHDL Testbench for LIFObuffer with VUnit framework
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
  constant CLK_PERIOD : time := 20 ns;  -- From: always #10 Clk = ~Clk;
  
  -- ========== Signals ==========
  signal Clk : std_logic := '0';
  signal Rst : std_logic := '1';
  signal EN : std_logic := '0';
  signal RW : std_logic := '0';
  signal dataIn : std_logic_vector(3 downto 0) := (others => '0');
  signal dataOut : std_logic_vector(3 downto 0);
  signal EMPTY : std_logic;
  signal FULL : std_logic;
  signal sim_done : boolean := false;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors : integer;
    clocks : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors => 0,
    clocks => 0
  );
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    while not sim_done loop
      Clk <= '0';
      wait for CLK_PERIOD / 2;
      Clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut : entity work.LIFObuffer
    port map (
      dataIn  => dataIn,
      dataOut => dataOut,
      RW      => RW,
      EN      => EN,
      Rst     => Rst,
      EMPTY   => EMPTY,
      FULL    => FULL,
      Clk     => Clk
    );
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initialize Inputs
    dataIn <= x"0";
    RW <= '0';
    EN <= '0';
    Rst <= '1';
    
    -- Wait 100 ns for global reset to finish
    wait for 100 ns;
    
    -- Add stimulus here
    EN <= '1';
    Rst <= '1';
    
    wait for 40 ns;
    Rst <= '0';
    RW <= '0';
    dataIn <= x"0";
    
    wait for 20 ns;
    dataIn <= x"2";
    
    wait for 20 ns;
    dataIn <= x"4";
    
    wait for 20 ns;
    dataIn <= x"6";
    
    wait for 20 ns;
    RW <= '1';
    
    -- Check FULL and EMPTY after 5 ns
    wait for 5 ns;
    if not (FULL = '1' and EMPTY = '0') then
      stats1.errors <= stats1.errors + 1;
    end if;
    
    wait for 20 ns;
    -- Check dataOut == 6
    if unsigned(dataOut) /= 6 then
      stats1.errors <= stats1.errors + 1;
    end if;
    
    wait for 20 ns;
    -- Check dataOut == 4
    if unsigned(dataOut) /= 4 then
      stats1.errors <= stats1.errors + 1;
    end if;
    
    wait for 20 ns;
    
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Clock Counter ==========
  clock_counter : process(Clk)
  begin
    if rising_edge(Clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
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
    -- Wait for simulation to complete
    wait until sim_done;
    wait for 10 ns;
    
    -- ========== Write to summary.txt ==========
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
           "/20 failures ===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;