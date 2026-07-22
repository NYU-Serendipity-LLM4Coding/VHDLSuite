-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Galois LFSR Test
-- Generates random reset pulses followed by long run
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    reset    : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    variable rand_int : integer;
    
  begin
    -- Initialize
    reset <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(400) @(posedge clk, negedge clk)
    -- reset <= !($random & 31);
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate random reset: !($random & 31)
      -- This means reset is 1 if ($random & 31) == 0
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      reset <= '1' when (rand_int = 0) else '0';
    end loop;
    
    -- Matches Verilog: @(posedge clk) reset <= 1'b0;
    wait until rising_edge(clk);
    reset <= '0';
    
    -- Matches Verilog: repeat(200000) @(posedge clk);
    for i in 1 to 200000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: reset <= 1'b1;
    reset <= '1';
    
    -- Matches Verilog: repeat(5) @(posedge clk);
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;