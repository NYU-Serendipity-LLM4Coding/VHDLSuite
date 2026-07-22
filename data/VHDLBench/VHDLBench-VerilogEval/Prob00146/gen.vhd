-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Serial Receiver FSM Test
-- Generates test patterns including predetermined sequences and random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk       : in  std_logic;
    signal_in : out std_logic;
    reset     : out std_logic;
    sim_done  : out boolean
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
    
    -- Random reset generator (matches Verilog: !($random & 31))
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '0' when (rand_int = 0) else '1';  -- ~1/32 chance of reset
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    signal_in <= '1';
    sim_done <= false;
    
    -- Matches Verilog: @(posedge clk);
    wait until rising_edge(clk);
    reset <= '0';
    signal_in <= '0';
    
    -- Matches Verilog: repeat(9) @(posedge clk);
    for i in 1 to 9 loop
      wait until rising_edge(clk);
    end loop;
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    for i in 1 to 9 loop
      wait until rising_edge(clk);
    end loop;
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    for i in 1 to 9 loop
      wait until rising_edge(clk);
    end loop;
    signal_in <= '1';
    
    wait until rising_edge(clk);
    
    -- Random test: repeat(800) @(posedge clk, negedge clk)
    for i in 1 to 800 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;