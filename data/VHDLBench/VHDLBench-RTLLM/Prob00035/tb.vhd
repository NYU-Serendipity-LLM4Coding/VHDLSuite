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
  -- ========== Constants ==========
  constant PERIOD : time := 10 ns;
  constant MAX_CYCLES : integer := 4000; -- Loop count from Verilog repeat(4000)

  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst : std_logic := '0'; -- Active high reset
  signal sim_done : boolean := false;

  -- DUT I/O
  signal Hours : std_logic_vector(5 downto 0);
  signal Mins  : std_logic_vector(5 downto 0);
  signal Secs  : std_logic_vector(5 downto 0);

  -- ========== Statistics ==========
  type stats_t is record
    errors : integer;
    errortime : time;
    clocks : integer;
  end record;

  signal stats1 : stats_t := (
    errors => 0,
    errortime => 0 ps,
    clocks => 0
  );

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
  dut1 : entity work.calendar
    port map (
      CLK   => clk,
      RST   => rst,
      Hours => Hours,
      Mins  => Mins,
      Secs  => Secs
    );

  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- Initial alignment and Reset sequence
    -- Verilog: #10 rst = 1;
    wait for 10 ns;
    rst <= '1';

    -- Verilog: #25 rst = 0;
    wait for 25 ns;
    rst <= '0';

    -- Verilog: repeat(4000) with #10 delays in between
    -- The verification happens in verify_process, we just wait for the duration
    wait for PERIOD * MAX_CYCLES;
    
    wait for PERIOD * 2; -- Extra margin
    
    sim_done <= true;
    wait;
  end process;

  -- ========== Verification & "Golden Model" ==========
  -- Implements the reference behavior to generate expected values on the fly
  verify_process : process(clk)
    variable ref_h : unsigned(5 downto 0) := (others => '0');
    variable ref_m : unsigned(5 downto 0) := (others => '0');
    variable ref_s : unsigned(5 downto 0) := (others => '0');
    
    variable first_check : boolean := true;
  begin
    if rising_edge(clk) then
      if not sim_done then
        -- Sync with the stimulus timing (Wait until T=35 when loop starts)
        -- The first functional clock edge is at 35ns (where RST goes low)
        if stats1.clocks < MAX_CYCLES and now >= 35 ns then
            
            -- 1. Compare DUT output (current state) with Expected Reference (calculated previously)
            -- Note: In the first cycle, both should be 0 due to reset
            if (unsigned(Hours) /= ref_h) or (unsigned(Mins) /= ref_m) or (unsigned(Secs) /= ref_s) then
                stats1.errors <= stats1.errors + 1;
                if stats1.errors = 0 then
                    stats1.errortime <= now;
                end if;
            end if;

            stats1.clocks <= stats1.clocks + 1;

            -- 2. Update Reference Model for NEXT cycle (matches DUT logic)
            if rst = '1' then
                ref_s := (others => '0');
                ref_m := (others => '0');
                ref_h := (others => '0');
            else
                if ref_s = 59 then
                    ref_s := (others => '0');
                    if ref_m = 59 then
                        ref_m := (others => '0');
                        if ref_h = 23 then
                            ref_h := (others => '0');
                        else
                            ref_h := ref_h + 1;
                        end if;
                    else
                        ref_m := ref_m + 1;
                    end if;
                else
                    ref_s := ref_s + 1;
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
    wait until sim_done;
    wait for PERIOD * 2;

    file_open(file_status, f, "summary.txt", write_mode);

    -- MANDATORY SUMMARY LINES
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

    -- Console Output
    info("========================================");
    info("Hint: Total mismatched samples is " & integer'image(stats1.errors) & 
         " out of " & integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");

    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed with " & integer'image(stats1.errors) & " errors.");
    end if;

    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;