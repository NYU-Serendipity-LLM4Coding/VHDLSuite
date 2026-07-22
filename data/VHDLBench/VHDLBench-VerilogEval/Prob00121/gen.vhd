-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for FSM Test
-- Generates reset and x input signals
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    reset    : out std_logic;
    x        : out std_logic;
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
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random reset generator (occasional reset)
    -- Matches Verilog: reset <= !($random & 63);
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 128.0));
      sig <= '0' when ((rand_int mod 64) /= 0) else '1';
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    x <= '0';
    sim_done <= false;
    
    -- Matches Verilog: @(posedge clk); @(posedge clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Matches Verilog: reset = 0;
    reset <= '0';
    
    -- Matches Verilog: @(posedge clk); @(posedge clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Matches Verilog: repeat(500) @(negedge clk)
    for i in 1 to 500 loop
      wait until falling_edge(clk);
      random_reset(reset);
      random_bit(x);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;