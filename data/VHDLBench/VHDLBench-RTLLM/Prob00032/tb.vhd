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
  constant PERIOD : time := 10 ns;
  
  signal clk : std_logic := '1';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  signal clk_div : std_logic;
  
  type stats_t is record
    errors              : integer;
    errortime           : time;
    errors_clk_div      : integer;
    errortime_clk_div   : time;
    clocks              : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors              => 0,
    errortime           => 0 ps,
    errors_clk_div      => 0,
    errortime_clk_div   => 0 ps,
    clocks              => 0
  );
  
  signal case_num_sig : integer := 0;
  
begin

  clk_process : process
  begin
    wait for PERIOD / 2;
    clk <= not clk;
  end process;
  
  dut1 : entity work.freq_divbyeven
    port map (
      clk      => clk,
      rst_n    => rst_n,
      clk_div  => clk_div
    );
  
  stimulus_process : process
  begin
    sim_done <= false;
    wait for 10 ns;
    rst_n <= '1';
    wait for 100 ns;
    sim_done <= true;
    wait;
  end process;
  
  verify_process : process
    variable case_num : integer := 0;
    variable expected_value : std_logic := '0';
  begin
    wait for 5 ns;
    
    -- From: for (i = 1; i < 20; i++)
    for i in 1 to 19 loop
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check current value against expected_value
        if clk_div /= expected_value then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_clk_div <= stats1.errors_clk_div + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_clk_div = 1 then
            stats1.errortime_clk_div <= now;
          end if;
        end if;
        
        -- Update expected_value for NEXT iteration
        -- From: if (i < 6) expected_value = 0;
        if i < 6 then
          expected_value := '0';
        elsif i < 12 then
          expected_value := '1';
        elsif i < 18 then
          expected_value := '0';
        else
          expected_value := '1';
        end if;
        
        case_num := case_num + 1;
        case_num_sig <= case_num;
      end if;
      
      wait for 5 ns;
    end loop;
    
    wait;
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
    wait for PERIOD * 2;
    
    file_open(file_status, f, "summary.txt", write_mode);
    
    if stats1.errors_clk_div > 0 then
      write(l, string'("Hint: Output 'clk_div' has "));
      write(l, stats1.errors_clk_div);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_clk_div / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'clk_div' has no mismatches."));
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
    
    if stats1.errors_clk_div > 0 then
      info("Hint: Output 'clk_div' has " & integer'image(stats1.errors_clk_div) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_clk_div / 1 ps) & ".");
    else
      info("Hint: Output 'clk_div' has no mismatches.");
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
           "/20 failures ===========");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;