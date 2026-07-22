-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for FSM Test
-- Generates reset and input signals with predetermined and random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    signal_in       : out std_logic;
    reset           : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Reset test task (simplified for VHDL)
    procedure reset_test is
      variable arfail, srfail, datafail : boolean;
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
    
    -- Wavedrom procedures (simplified)
    procedure wavedrom_start is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    signal_in <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog initial block sequence
    wait until rising_edge(clk);
    reset <= '0';
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    -- Wavedrom section start
    wavedrom_start;
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    -- No change to inputs
    
    wait until falling_edge(clk);
    reset <= '1';
    
    wait until rising_edge(clk);
    reset <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- signal_in <= $random
      random_bit(signal_in);
      
      -- reset <= !($random & 31)
      -- This means reset is 1 when ($random & 31) == 0, which happens ~3% of time
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      reset <= '1' when rand_int = 0 else '0';
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;