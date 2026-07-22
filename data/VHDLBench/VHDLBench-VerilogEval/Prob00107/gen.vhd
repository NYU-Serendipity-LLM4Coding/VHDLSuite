-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Moore State Machine Test
-- Generates input and reset signals with synchronous reset testing
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    signal_in       : out std_logic;
    signal_reset    : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1 : positive := 12345;
    variable seed2 : positive := 67890;
    variable rand_val : real;
    variable arfail, srfail, datafail : boolean;
    
    -- Random bit generator procedure
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random with probability procedure (replaces function)
    procedure random_with_prob(signal sig : out std_logic; prob : real) is
    begin
      uniform(seed1, seed2, rand_val);
      if rand_val < prob then
        sig <= '1';
      else
        sig <= '0';
      end if;
    end procedure;
    
    -- Reset test procedure (matches Verilog reset_test)
    procedure reset_test is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      signal_reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      signal_reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      signal_reset <= '0';
      
      if srfail then
        report "Hint: Your reset doesn't seem to be working." severity note;
      elsif arfail and not datafail then
        report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
      end if;
    end procedure;
    
  begin
    -- Initialize
    signal_reset <= '1';
    signal_in <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial sequence (matches Verilog initial block)
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    signal_reset <= '0';
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    -- Wavedrom section
    wavedrom_enable <= '1';
    
    -- Call reset_test (synchronous)
    reset_test;
    
    -- Specific test sequence
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    -- Matches Verilog: reset <= !($random & 7);
    -- This gives reset probability of ~1/8 (when lower 3 bits are all 0)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
      random_with_prob(signal_reset, 0.125);  -- Approximate !($random & 7)
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;