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
  -- ========== Constants (from Verilog parameters) ==========
  constant PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal data_in : std_logic_vector(7 downto 0) := (others => '0');
  signal valid_in : std_logic := '0';
  signal valid_out : std_logic;
  signal data_out : std_logic_vector(9 downto 0);
  
  -- ========== Expected Values (from Verilog reg result[...]) ==========
  type result_array_t is array (0 to 2) of unsigned(9 downto 0);
  constant expected_results : result_array_t := (
    0 => to_unsigned(20, 10),   -- 1+2+3+14 = 20
    1 => to_unsigned(114, 10),  -- 5+2+103+4 = 114
    2 => to_unsigned(68, 10)    -- 5+6+3+54 = 68
  );
  
  constant expected_cases : integer := 3;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_data_out    : integer;
    errortime_data_out : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_data_out    => 0,
    errortime_data_out => 0 ps,
    clocks             => 0
  );
  
  -- For sharing case count (use signal instead of shared variable)
  signal case_num_shared : integer := 0;
  
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
  dut1 : entity work.accu
    port map (
      clk       => clk,
      rst_n     => rst_n,
      data_in   => data_in,
      valid_in  => valid_in,
      valid_out => valid_out,
      data_out  => data_out
    );
  
  -- ========== Stimulus Generation (from Verilog initial blocks) ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: #(PERIOD*2) rst_n = 1;
    wait for PERIOD * 2;
    rst_n <= '1';
    
    -- From: #(PERIOD*1+0.01);
    wait for PERIOD * 1 + 10 ps;
    
    -- From: #(PERIOD) data_in = 8'd1; valid_in = 1;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(1, 8));
    valid_in <= '1';
    
    -- From: #(PERIOD) data_in = 8'd2;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(2, 8));
    
    -- From: #(PERIOD) data_in = 8'd3;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(3, 8));
    
    -- From: #(PERIOD) data_in = 8'd14;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(14, 8));
    
    -- From: #(PERIOD) data_in = 8'd5;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(5, 8));
    
    -- From: #(PERIOD) data_in = 8'd2;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(2, 8));
    
    -- From: #(PERIOD) data_in = 8'd103;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(103, 8));
    
    -- From: #(PERIOD) data_in = 8'd4;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(4, 8));
    
    -- From: #(PERIOD) data_in = 8'd5;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(5, 8));
    
    -- From: #(PERIOD) data_in = 8'd6;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(6, 8));
    
    -- From: #(PERIOD) data_in = 8'd3;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(3, 8));
    
    -- From: #(PERIOD) data_in = 8'd54;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(54, 8));
    
    -- From: #(PERIOD*2);
    wait for PERIOD * 2;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- From: if (valid_out) { error = (data_out == result[casenum]) ? error : error + 1; }
        if valid_out = '1' then
          -- Check data_out against expected value
          if unsigned(data_out) /= expected_results(case_num) then
            -- Increment error counters
            stats1.errors <= stats1.errors + 1;
            stats1.errors_data_out <= stats1.errors_data_out + 1;
            
            -- Record first error time
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_data_out = 1 then
              stats1.errortime_data_out <= now;
            end if;
          end if;
          
          -- Increment case counter
          case_num := case_num + 1;
          case_num_shared <= case_num;  -- Update signal for report_process
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
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_data_out > 0 then
      write(l, string'("Hint: Output 'data_out' has "));
      write(l, stats1.errors_data_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_data_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'data_out' has no mismatches."));
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
    
    if stats1.errors_data_out > 0 then
      info("Hint: Output 'data_out' has " & integer'image(stats1.errors_data_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_data_out / 1 ps) & ".");
    else
      info("Hint: Output 'data_out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
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