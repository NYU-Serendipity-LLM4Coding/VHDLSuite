-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-bit Adder Test
-- Generates random 4-bit inputs x and y on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    x        : out std_logic_vector(3 downto 0);
    y        : out std_logic_vector(3 downto 0);
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  -- Helper signal for 8-bit concatenation {x,y}
  signal xy_concat : std_logic_vector(7 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- xy_concat = {x, y} in Verilog notation
  x <= xy_concat(7 downto 4);
  y <= xy_concat(3 downto 0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 8-bit vector generator (replaces Verilog $random)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      xy_concat <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
  begin
    -- Initialize
    xy_concat <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
    -- This means 100 clock edges (alternating rising and falling)
    for i in 1 to 100 loop
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