-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for FSM Next-State Logic Test
-- Generates random combinations of state (y) and input (w)
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    y        : out std_logic_vector(3 downto 1);
    w        : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 4-bit vector generator (for {y,w})
    procedure random_vector is
      variable temp_vec : std_logic_vector(3 downto 0);
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      temp_vec := std_logic_vector(to_unsigned(rand_int, 4));
      -- Split: {y[3:1], w} = temp_vec[3:0]
      y <= temp_vec(3 downto 1);
      w <= temp_vec(0);
    end procedure;
    
  begin
    -- Initialize
    y <= "000";
    w <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
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