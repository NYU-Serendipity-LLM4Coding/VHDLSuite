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

  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal sim_done : boolean := false;
  signal check_enable : std_logic := '0';

  -- DUT I/O
  signal dividend : std_logic_vector(7 downto 0) := (others => '0');
  signal divisor : std_logic_vector(7 downto 0) := (others => '0');
  signal sign : std_logic := '0';
  signal opn_valid : std_logic := '0';
  signal res_valid : std_logic;
  signal res_ready : std_logic := '0';
  signal result : std_logic_vector(15 downto 0);

  -- ========== Expected Values ==========
  type byte_array_t is array (0 to 7) of std_logic_vector(7 downto 0);
  type result_array_t is array (0 to 7) of std_logic_vector(15 downto 0);
  type bit_array_t is array (0 to 7) of std_logic;

  constant a_test : byte_array_t := (
    0 => std_logic_vector(to_unsigned(100, 8)),
    1 => std_logic_vector(to_signed(-100, 8)),
    2 => std_logic_vector(to_unsigned(100, 8)),
    3 => std_logic_vector(to_signed(-100, 8)),
    4 => std_logic_vector(to_unsigned(123, 8)),
    5 => std_logic_vector(to_unsigned(0, 8)),
    6 => std_logic_vector(to_unsigned(123, 8)),
    7 => std_logic_vector(to_unsigned(255, 8))
  );

  constant b_test : byte_array_t := (
    0 => std_logic_vector(to_unsigned(10, 8)),
    1 => std_logic_vector(to_unsigned(10, 8)),
    2 => std_logic_vector(to_signed(-10, 8)),
    3 => std_logic_vector(to_signed(-10, 8)),
    4 => std_logic_vector(to_unsigned(123, 8)),
    5 => std_logic_vector(to_unsigned(123, 8)),
    6 => std_logic_vector(to_unsigned(251, 8)),
    7 => std_logic_vector(to_unsigned(7, 8))
  );

  constant sign_test : bit_array_t := (
    0 => '0', 1 => '1', 2 => '1', 3 => '1',
    4 => '0', 5 => '0', 6 => '0', 7 => '0'
  );

  constant expected_results : result_array_t := (
    0 => x"000A", 
    1 => x"00F6", 
    2 => x"00F6", 
    3 => x"000A", 
    4 => x"0001", 
    5 => x"0000", 
    6 => x"7B00", 
    7 => x"0324"
  );

  constant expected_cases : integer := 8;

  -- ========== Statistics ==========
  type stats_t is record
    errors : integer;
    errortime : time;
    errors_result : integer;
    errortime_result : time;
    clocks : integer;
  end record;

  signal stats1 : stats_t := (
    errors => 0,
    errortime => 0 ps,
    errors_result => 0,
    errortime_result => 0 ps,
    clocks => 0
  );

  signal case_num_shared : integer := 0;

begin

  clk_process : process
  begin
    clk <= '0';
    wait for PERIOD / 2;
    clk <= '1';
    wait for PERIOD / 2;
  end process;

  dut1 : entity work.TopModule
    port map (
      clk => clk,
      rst => rst,
      dividend => dividend,
      divisor => divisor,
      sign => sign,
      opn_valid => opn_valid,
      res_valid => res_valid,
      res_ready => res_ready,
      result => result
    );

  stimulus_process : process
  begin
    sim_done <= false;
    check_enable <= '0';

    rst <= '1';
    opn_valid <= '0';
    res_ready <= '1';
    wait for PERIOD * 2;
    rst <= '0';

    for i in 0 to expected_cases - 1 loop
      dividend <= a_test(i);
      divisor <= b_test(i);
      sign <= sign_test(i);
      opn_valid <= '1';
      wait for PERIOD * 1;
      opn_valid <= '0';

      wait until res_valid = '1';
      wait for PERIOD * 1;

      -- Sync Check to clock
      wait until rising_edge(clk);
      check_enable <= '1';
      wait until rising_edge(clk);
      check_enable <= '0';
      
      wait for PERIOD / 2;
      res_ready <= '1';
      wait for PERIOD * 1;
    end loop;

    wait for PERIOD * 5;
    sim_done <= true;
    wait;
  end process;

  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      if not sim_done then
        if check_enable = '1' then
           stats1.clocks <= stats1.clocks + 1;

           if result /= expected_results(case_num) then
             stats1.errors <= stats1.errors + 1;
             stats1.errors_result <= stats1.errors_result + 1;
             
             if stats1.errors = 0 then
               stats1.errortime <= now;
             end if;
             if stats1.errors_result = 0 then
               stats1.errortime_result <= now;
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
    wait for PERIOD * 2;

    file_open(file_status, f, "summary.txt", write_mode);

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
    if stats1.errors_result > 0 then
        info("Hint: Output 'result' has " & integer'image(stats1.errors_result) & 
             " mismatches. First mismatch occurred at time " & 
             integer'image(stats1.errortime_result / 1 ps) & ".");
    else
        info("Hint: Output 'result' has no mismatches.");
    end if;

    info("Hint: Total mismatched samples is " & integer'image(stats1.errors) & 
         " out of " & integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");

    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed.");
    end if;

    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;

