-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 100-bit Vector Neighbor Comparison
-- Generates random 100-bit input vectors on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk       : in  std_logic;
    tb_match  : in  boolean;
    signal_in : out std_logic_vector(99 downto 0);
    sim_done  : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 123456;
    variable seed2    : positive := 789012;
    variable rand_val : real;
    variable rand_vec : std_logic_vector(99 downto 0);
    
    -- Generate random 100-bit vector (replaces Verilog $random)
    procedure random_vector(signal vec : out std_logic_vector(99 downto 0)) is
      variable temp : std_logic_vector(99 downto 0);
    begin
      -- Generate random bits in chunks
      for i in 0 to 99 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      vec <= temp;
    end procedure;
    
  begin
    -- Initialize
    sim_done <= false;
    
    -- Matches Verilog: in <= $random;
    random_vector(signal_in);
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(100)
    for i in 1 to 100 loop
      -- @(negedge clk) in <= $random;
      wait until falling_edge(clk);
      random_vector(signal_in);
      
      -- @(posedge clk) in <= $random;
      wait until rising_edge(clk);
      random_vector(signal_in);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;