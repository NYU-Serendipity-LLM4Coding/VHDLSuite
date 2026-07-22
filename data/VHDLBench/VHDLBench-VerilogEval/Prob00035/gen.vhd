-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Decade Counter Test
-- Tests synchronous reset and counting from 1 to 10
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
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
    
    -- Reset test procedure (matches Verilog reset_test task)
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
      
      -- Note: Verilog $display statements are handled in testbench reporting
    end procedure;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Reset test
    reset_test;
    
    -- Count for 12 clocks
    for i in 1 to 12 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    
    -- Random reset testing: repeat(400) @(posedge clk, negedge clk)
    -- Matches Verilog: reset <= !($random & 31);
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate random value: !($random & 31)
      -- This means: if ($random & 31) == 0, then reset = 1, else reset = 0
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));  -- 0 to 31
      reset <= '1' when (rand_int = 0) else '0';
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;