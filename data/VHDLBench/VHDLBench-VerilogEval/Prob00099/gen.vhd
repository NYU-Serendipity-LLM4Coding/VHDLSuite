-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for One-Hot State Machine
-- Tests one-hot encoded state vectors with random input w
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    y        : out std_logic_vector(6 downto 1);
    w        : out std_logic;
    tb_match : in  boolean;
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
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Generate one-hot vector (1 << position)
    procedure one_hot_vector(position : integer; signal vec : out std_logic_vector) is
      variable temp : std_logic_vector(6 downto 1) := (others => '0');
    begin
      temp(position) := '1';
      vec <= temp;
    end procedure;
    
  begin
    -- Initialize
    y <= (others => '0');
    w <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    -- Test one-hot cases: y <= 1 << ($unsigned($random) % 6);
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate random position (0 to 5) and create one-hot vector
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 6.0));
      one_hot_vector(rand_int + 1, y);  -- y[6:1], so position 1 to 6
      
      -- Random w input
      random_bit(w);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;