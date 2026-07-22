-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Boolean Function Test
-- Generates random 2-bit input patterns on clock edges
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
  signal xy_vector : std_logic_vector(1 downto 0);
begin

  -- Split vector to individual outputs
  x <= xy_vector(1);
  y <= xy_vector(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 2-bit vector generator (replaces Verilog $random % 4)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      xy_vector <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
  begin
    -- Initialize
    xy_vector <= "00";
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: always @(posedge clk, negedge clk) {x, y} <= $random % 4;
    -- This runs continuously, generating new values on each clock edge
    
    -- Matches Verilog: repeat(101) @(negedge clk);
    for i in 1 to 101 loop
      wait until falling_edge(clk);
      random_vector;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;