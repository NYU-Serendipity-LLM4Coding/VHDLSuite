-- (2) Testbench (tb entity)
-- Main Testbench for Branch History Register
-- Verifies branch prediction history with misprediction handling
-- Corresponds to Verilog module: tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity tb;

architecture sim of tb is
  
  -- Clock
  signal clk : std_logic := '0';
  constant clk_period : time := 10 ps;
  
  -- DUT signals
  signal areset              : std_logic := '0';
  signal predict_valid       : std_logic := '0';
  signal predict_taken       : std_logic := '0';
  signal train_mispredicted  : std_logic := '0';
  signal train_taken         : std_logic := '0';
  signal train_history       : std_logic_vector(31 downto 0) := (others => '0');
  signal predict_history_ref : std_logic_vector(31 downto 0);
  signal predict_history_dut : std_logic_vector(31 downto 0);
  
  -- Stimulus control
  signal wavedrom_title : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal wavedrom_hide_after_time : integer;
  signal sim_done : boolean := false;
  
  -- Statistics
  type stats_t is record
    errors                      : integer;
    errortime                   : time;
    errors_predict_history      : integer;
    errortime_predict_history   : time;
    clocks                      : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors                    => 0,
    errortime                 => 0 ps,
    errors_predict_history    => 0,
    errortime_predict_history => 0 ps,
    clocks                    => 0
  );
  
  -- Verification
  signal tb_match : boolean;
  signal tb_mismatch : boolean;
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation
  -----------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;
  
  -----------------------------------------------------------------------------
  -- Stimulus generator instantiation
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk                      => clk,
      areset                   => areset,
      predict_valid            => predict_valid,
      predict_taken            => predict_taken,
      train_mispredicted       => train_mispredicted,
      train_taken              => train_taken,
      train_history            => train_history,
      tb_match                 => tb_match,
      wavedrom_title           => wavedrom_title,
      wavedrom_enable          => wavedrom_enable,
      wavedrom_hide_after_time => wavedrom_hide_after_time,
      sim_done                 => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk              => clk,
      areset           => areset,
      predict_valid    => predict_valid,
      predict_taken    => predict_taken,
      predict_history  => predict_history_ref,
      train_mispredicted => train_mispredicted,
      train_taken      => train_taken,
      train_history    => train_history
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk              => clk,
      areset           => areset,
      predict_valid    => predict_valid,
      predict_taken    => predict_taken,
      predict_history  => predict_history_dut,
      train_mispredicted => train_mispredicted,
      train_taken      => train_taken,
      train_history    => train_history
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -----------------------------------------------------------------------------
  tb_match <= (predict_history_ref = predict_history_dut) or 
              (predict_history_ref = (predict_history_ref xor predict_history_dut xor predict_history_ref));
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Check predict_history
        if predict_history_ref /= predict_history_dut then
          if stats1.errors_predict_history = 0 then
            stats1.errortime_predict_history <= now;
          end if;
          stats1.errors_predict_history <= stats1.errors_predict_history + 1;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- VUnit runner process
  -----------------------------------------------------------------------------
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 1000000 ps;
    
    -- Write summary
    if stats1.errors_predict_history > 0 then
      write(l, string'("Hint: Output 'predict_history' has "));
      write(l, stats1.errors_predict_history);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_predict_history / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'predict_history' has no mismatches."));
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
    
    -- Console output
    info("========================================");
    if stats1.errors_predict_history > 0 then
      info("Hint: Output 'predict_history' has " & integer'image(stats1.errors_predict_history) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_predict_history / 1 ps) & " ps.");
    else
      info("Hint: Output 'predict_history' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & 
                   " mismatches in " & integer'image(stats1.clocks) & " samples");
    else
      info("PASS: All " & integer'image(stats1.clocks) & " samples matched!");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;