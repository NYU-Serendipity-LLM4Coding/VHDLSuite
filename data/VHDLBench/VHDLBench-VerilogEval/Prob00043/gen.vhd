-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Pairwise Comparison Test
-- Generates random 5-bit input combinations
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    a        : out std_logic;
    b        : out std_logic;
    c        : out std_logic;
    d        : out std_logic;
    e        : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal inputs : std_logic_vector(4 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, c, d, e}
  a <= inputs(4);
  b <= inputs(3);
  c <= inputs(2);
  d <= inputs(1);
  e <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 5-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 5));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "00000";
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;