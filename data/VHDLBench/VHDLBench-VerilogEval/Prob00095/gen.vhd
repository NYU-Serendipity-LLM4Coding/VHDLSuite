-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Shift Enable FSM Test
-- Generates random reset signals on negative clock edges
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
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random reset generator
    -- Matches Verilog: reset <= !($random & 31);
    -- This means reset is '1' when ($random & 31) == 0
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));  -- 0 to 31
      sig <= '1' when (rand_int = 0) else '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(100) @(negedge clk)
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;