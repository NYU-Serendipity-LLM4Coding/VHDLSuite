-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Hierarchical Module Test
-- Generates random 2-bit patterns on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    x        : out std_logic;
    y        : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal xy_vec : std_logic_vector(1 downto 0);
begin

  x <= xy_vec(1);
  y <= xy_vec(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    procedure random_2bit is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      xy_vec <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
  begin
    xy_vec <= "00";
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: always @(posedge clk, negedge clk) {x, y} <= $random % 4;
    -- repeat(100) @(negedge clk);
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      random_2bit;
      wait until rising_edge(clk);
      random_2bit;
    end loop;
    
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;