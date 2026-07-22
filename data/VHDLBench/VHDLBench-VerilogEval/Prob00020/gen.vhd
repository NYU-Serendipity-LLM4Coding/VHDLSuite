-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 2-bit Equality Comparator Test
-- Generates random 2-bit inputs A and B on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    A        : out std_logic_vector(1 downto 0);
    B        : out std_logic_vector(1 downto 0);
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  -- Helper signal for 4-bit concatenation {A, B}
  signal inputs : std_logic_vector(3 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {A[1:0], B[1:0]}
  A <= inputs(3 downto 2);
  B <= inputs(1 downto 0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Generate random 4-bit value (replaces Verilog: $random % 16)
    procedure random_4bit is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "0000";
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(1000) @(negedge clk)
    for i in 1 to 1000 loop
      wait until falling_edge(clk);
      random_4bit;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;