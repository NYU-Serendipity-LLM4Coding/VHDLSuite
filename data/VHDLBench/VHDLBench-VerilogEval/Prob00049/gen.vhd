-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for D Flip-Flop with Async Reset Test
-- Generates random d and ar (async reset) signals on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    d        : out std_logic;
    ar       : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 2-bit generator (replaces Verilog $random)
    procedure random_bits(signal d_sig : out std_logic; signal ar_sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      d_sig  <= '1' when (rand_int mod 2) = 1 else '0';
      ar_sig <= '1' when (rand_int / 2) = 1 else '0';
    end procedure;
    
  begin
    -- Initialize
    d <= '0';
    ar <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bits(d, ar);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;