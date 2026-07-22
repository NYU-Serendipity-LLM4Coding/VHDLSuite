-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for State Machine Test
-- Generates random reset and w input signals
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    reset    : out std_logic;
    w        : out std_logic;
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
    
    -- Random reset generator (reset when random & 15 == 0)
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= '1' when (rand_int mod 16) = 0 else '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '0';
    w <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(w);
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;