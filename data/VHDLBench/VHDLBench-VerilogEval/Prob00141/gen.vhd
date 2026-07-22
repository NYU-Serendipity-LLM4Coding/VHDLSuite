-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 12-hour BCD Clock Test
-- Generates reset and enable signals, monitors for BCD violations
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    reset           : out std_logic;
    ena             : out std_logic;
    hh_dut          : in  std_logic_vector(7 downto 0);
    mm_dut          : in  std_logic_vector(7 downto 0);
    ss_dut          : in  std_logic_vector(7 downto 0);
    pm_dut          : in  std_logic;
    tb_match        : in  boolean;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal bcd_fail   : std_logic := '0';
  signal reset_fail : std_logic := '0';
begin

  -- BCD violation detector
  bcd_check : process(clk)
  begin
    if rising_edge(clk) then
      if (unsigned(hh_dut(3 downto 0)) >= 10) or
         (unsigned(hh_dut(7 downto 4)) >= 10) or
         (unsigned(mm_dut(3 downto 0)) >= 10) or
         (unsigned(mm_dut(7 downto 4)) >= 10) or
         (unsigned(ss_dut(3 downto 0)) >= 10) or
         (unsigned(ss_dut(7 downto 4)) >= 10) then
        bcd_fail <= '1';
      end if;
    end if;
  end process;

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    
    -- Random boolean generator
    function random_bool(threshold : integer) return std_logic is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      if integer(floor(r * real(threshold))) = 0 then
        return '1';
      else
        return '0';
      end if;
    end function;
    
    -- Wavedrom tasks (simplified)
    procedure wavedrom_start(title : string) is
    begin
      wavedrom_enable <= '1';
      wait for 0 ps;
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
    -- Reset test task
    procedure reset_test is
      variable arfail   : boolean := false;
      variable srfail   : boolean := false;
      variable datafail : boolean := false;
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      if srfail then
        report "Hint: Your reset doesn't seem to be working." severity note;
      elsif arfail and (false or not datafail) then
        report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
      end if;
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    ena <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Test sequence
    wavedrom_start("Reset and count to 10");
    reset_test;
    
    for i in 1 to 12 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    -- Check reset value
    ena <= '1';
    reset <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    if not tb_match then
      report "Hint: Clock seems to reset to incorrect value (Should be 12:00:00 AM)." severity note;
      reset_fail <= '1';
    end if;
    
    reset <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Test reset priority over enable
    ena <= '0';
    reset <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    if not tb_match and reset_fail = '0' then
      report "Hint: Reset has higher priority than enable and should occur even if not enabled." severity note;
    end if;
    
    -- Random reset and enable
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      reset <= random_bool(32);
      ena   <= random_bool(4);
    end loop;
    
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '1';
    ena   <= '1';
    
    -- Count to minute rollover
    for i in 1 to 55 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_start("Minute roll-over");
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    wavedrom_stop;
    
    -- Count to hour rollover
    for i in 1 to 3530 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_start("Hour roll-over");
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    wavedrom_stop;
    
    -- Count to PM rollover
    for i in 1 to 39590 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_start("PM roll-over");
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    wavedrom_stop;
    
    -- Long count with random enable
    for i in 1 to 132745 loop
      wait until rising_edge(clk);
    end loop;
    
    for i in 1 to 50 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      ena <= random_bool(8);
    end loop;
    
    reset <= '1';
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Final BCD check message
    if bcd_fail = '1' then
      report "Hint: Non-BCD values detected. Are you sure you're using two-digit BCD representation for hh, mm, and ss?" severity note;
    end if;
    
    -- Wait for #1 to match Verilog timing
    wait for 1 ps;
    
    -- CRITICAL: Signal completion AFTER all stimulus
    sim_done <= true;
    
    -- Keep process alive indefinitely
    wait;
  end process;

end architecture behavioral;