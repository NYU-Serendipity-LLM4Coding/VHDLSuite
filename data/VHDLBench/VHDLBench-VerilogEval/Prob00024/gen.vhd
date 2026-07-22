-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Half Adder Test
-- Generates random inputs on both clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    a        : out std_logic;
    b        : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal inputs : std_logic_vector(1 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b}
  a <= inputs(1);
  b <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 2-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "00";
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: always @(posedge clk, negedge clk) {a,b} <= $random;
    -- This runs continuously, generating random values on every clock edge
    -- The stimulus stops after repeat(100) @(negedge clk)
    
    -- Generate random values on clock edges for 100 negedge clk cycles
    for i in 1 to 200 loop  -- 200 edges = 100 full clock cycles
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