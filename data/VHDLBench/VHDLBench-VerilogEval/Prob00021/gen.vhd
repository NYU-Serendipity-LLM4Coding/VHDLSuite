-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 256-to-1 Multiplexer Test
-- Generates random 1024-bit input and 8-bit selector
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    signal_in: out std_logic_vector(1023 downto 0);
    sel      : out std_logic_vector(7 downto 0);
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable temp_in  : std_logic_vector(1023 downto 0);
    variable temp_sel : std_logic_vector(7 downto 0);
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    sel <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(1000) @(negedge clk);
    for rep in 1 to 1000 loop
      wait until falling_edge(clk);
      
      -- Generate random values for in (32 segments of 32 bits each)
      -- Matches Verilog: for (int i=0;i<32; i++) in[i*32+:32] <= $random;
      for i in 0 to 31 loop
        for bit_idx in 0 to 31 loop
          uniform(seed1, seed2, rand_val);
          temp_in(i*32 + bit_idx) := '1' when rand_val > 0.5 else '0';
        end loop;
      end loop;
      signal_in <= temp_in;
      
      -- Generate random selector
      -- Matches Verilog: sel <= $random;
      for bit_idx in 0 to 7 loop
        uniform(seed1, seed2, rand_val);
        temp_sel(bit_idx) := '1' when rand_val > 0.5 else '0';
      end loop;
      sel <= temp_sel;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;