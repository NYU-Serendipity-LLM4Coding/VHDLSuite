-- (1) Testbench with integrated stimulus (tb entity)
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
  constant CLK_PERIOD : time := 10 ns;
  
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '1';
  signal sim_done : boolean := false;
  signal Q : std_logic_vector(63 downto 0);
  
  type result_array_t is array (0 to 3) of std_logic_vector(63 downto 0);
  constant expected_results : result_array_t := (
    0 => X"FFFFF00000000000",  -- 20 clocks: 20个1 + 44个0
    1 => X"FFFFFFFFFFFFFFFF",  -- 64 clocks: 全1
    2 => X"7FFFFFFFFFFFFFFF",  -- 65 clocks: MSB=0, 其余63个1
    3 => X"0000000000000001"   -- 127 clocks: 只有LSB=1
  );
  
  constant expected_cases : integer := 4;
  
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_Q           : integer;
    errortime_Q        : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_Q           => 0,
    errortime_Q        => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  signal check_enable : std_logic := '0';
  signal expected_value : std_logic_vector(63 downto 0) := (others => '0');
  
begin

  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;
  
  dut1 : entity work.JC_counter
    port map (
      clk   => clk,
      rst_n => rst_n,
      Q     => Q
    );
  
  stimulus_process : process
  begin
    sim_done <= false;
    check_enable <= '0';
    rst_n <= '1';
    
    wait for CLK_PERIOD * 2;
    rst_n <= '0';
    wait for CLK_PERIOD * 2;
    rst_n <= '1';
    
    -- Check 1: after 20 clocks
    wait for CLK_PERIOD * 20;
    expected_value <= expected_results(0);
    check_enable <= '1';
    wait until rising_edge(clk);
    check_enable <= '0';
    
    -- Check 2: after 44 more clocks (total 64)
    wait for CLK_PERIOD * 44;
    expected_value <= expected_results(1);
    check_enable <= '1';
    wait until rising_edge(clk);
    check_enable <= '0';
    
    -- Check 3: after 1 more clock (total 65)
    wait for CLK_PERIOD * 1;
    expected_value <= expected_results(2);
    check_enable <= '1';
    wait until rising_edge(clk);
    check_enable <= '0';
    
    -- Check 4: after 62 more clocks (total 127)
    wait for CLK_PERIOD * 62;
    expected_value <= expected_results(3);
    check_enable <= '1';
    wait until rising_edge(clk);
    check_enable <= '0';
    
    wait for CLK_PERIOD * 5;
    sim_done <= true;
    wait;
  end process;
  
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        if check_enable = '1' then
          if Q /= expected_value then
            stats1.errors <= stats1.errors + 1;
            stats1.errors_Q <= stats1.errors_Q + 1;
            
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_Q = 1 then
              stats1.errortime_Q <= now;
            end if;
          end if;
          
          case_num := case_num + 1;
          case_num_shared <= case_num;
        end if;
      end if;
    end if;
  end process;
  
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  report_process : process
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    wait until sim_done;
    wait for CLK_PERIOD * 2;
    
    file_open(file_status, f, "summary.txt", write_mode);
    
    if stats1.errors_Q > 0 then
      write(l, string'("Hint: Output 'Q' has "));
      write(l, stats1.errors_Q);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_Q / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'Q' has no mismatches."));
      writeline(f, l);
    end if;
    
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
    
    info("========================================");
    
    if stats1.errors_Q > 0 then
      info("Hint: Output 'Q' has " & integer'image(stats1.errors_Q) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_Q / 1 ps) & ".");
    else
      info("Hint: Output 'Q' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;