-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Motor Control FSM Test
-- Generates reset and random x, y inputs
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    resetn   : out std_logic;
    x        : out std_logic;
    y        : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 123;
    variable seed2    : positive := 456;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random reset generator (resetn = 0 with probability ~1/32)
    procedure random_resetn(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '0' when rand_int = 0 else '1';
    end procedure;
    
  begin
    -- Initialize
    resetn <= '0';
    x <= '0';
    y <= '0';
    sim_done <= false;
    
    -- Matches Verilog: @(posedge clk); @(posedge clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Matches Verilog: resetn = 1;
    resetn <= '1';
    
    -- Matches Verilog: repeat(500) @(negedge clk)
    for i in 1 to 500 loop
      wait until falling_edge(clk);
      -- resetn <= ($random & 31) != 0;
      random_resetn(resetn);
      -- {x,y} <= $random;
      random_bit(x);
      random_bit(y);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;