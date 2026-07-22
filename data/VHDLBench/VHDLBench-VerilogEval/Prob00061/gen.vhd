-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Shift Register Stage Test
-- Generates random inputs for w, R, E, L on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    w        : out std_logic;
    R        : out std_logic;
    E        : out std_logic;
    L        : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal inputs : std_logic_vector(3 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {w, R, E, L}
  w <= inputs(3);
  R <= inputs(2);
  E <= inputs(1);
  L <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 4-bit vector generator
    procedure random_vector is
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
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    -- 200 clock edges (alternating rising and falling)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;