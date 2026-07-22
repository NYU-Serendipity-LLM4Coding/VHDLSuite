-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Bit Reversal Test
-- Generates random 100-bit input vectors on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk       : in  std_logic;
    signal_in : out std_logic_vector(99 downto 0);
    sim_done  : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: always @(posedge clk, negedge clk) in <= {$random, ...};
    -- This generates new values on every clock edge
    -- Matches Verilog: repeat(100) @(negedge clk);
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      
      -- Generate random 100-bit vector (matches Verilog: {$random, $random, $random, $random})
      -- Note: 4 * 32 = 128 bits, but we only use 100 bits
      for bit_idx in 0 to 99 loop
        uniform(seed1, seed2, rand_val);
        signal_in(bit_idx) <= '1' when rand_val > 0.5 else '0';
      end loop;
    end loop;
    
    -- After the repeat loop, we need one more edge for the last value to propagate
    wait until falling_edge(clk);
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;