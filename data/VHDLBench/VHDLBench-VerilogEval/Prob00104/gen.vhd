-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Flip-Flop with 2:1 Mux Test
-- Generates random inputs on both clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    L        : out std_logic;
    r_in     : out std_logic;
    q_in     : out std_logic;
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
    
    -- Generate random 3-bit value for {L, r_in, q_in}
    procedure random_inputs is
      variable temp : std_logic_vector(2 downto 0);
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));  -- 0 to 7
      temp := std_logic_vector(to_unsigned(rand_int, 3));
      L    <= temp(2);
      r_in <= temp(1);
      q_in <= temp(0);
    end procedure;
    
  begin
    -- Initialize
    L    <= '0';
    r_in <= '0';
    q_in <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: always @(posedge clk, negedge clk)
    -- This generates inputs on both rising and falling edges
    -- The loop runs 200 times (100 posedge + 100 negedge based on repeat(100) @(posedge clk))
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_inputs;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;