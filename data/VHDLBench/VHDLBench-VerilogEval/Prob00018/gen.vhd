-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 256-to-1 Multiplexer Test
-- Generates random 256-bit input vector and 8-bit selector
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk       : in  std_logic;
    signal_in : out std_logic_vector(255 downto 0);
    sel       : out std_logic_vector(7 downto 0);
    sim_done  : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable temp_in  : std_logic_vector(255 downto 0);
    variable temp_sel : std_logic_vector(7 downto 0);
    
    -- Generate random 32-bit vector (returns a value instead of out parameter)
    impure function random_32bit return std_logic_vector is
      variable temp : std_logic_vector(31 downto 0);
    begin
      for i in 0 to 31 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      return temp;
    end function;
    
    -- Generate random 8-bit vector
    impure function random_8bit return std_logic_vector is
      variable temp : std_logic_vector(7 downto 0);
    begin
      for i in 0 to 7 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      return temp;
    end function;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    sel <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(1000) @(negedge clk);
    for iteration in 1 to 1000 loop
      wait until falling_edge(clk);
      
      -- Matches Verilog: always @(posedge clk, negedge clk)
      -- for (int i=0;i<8; i++) in[i*32+:32] <= $random;
      -- Generate 8 chunks of 32 bits each
      for i in 0 to 7 loop
        temp_in(i*32+31 downto i*32) := random_32bit;
      end loop;
      signal_in <= temp_in;
      
      -- sel <= $random;
      temp_sel := random_8bit;
      sel <= temp_sel;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;