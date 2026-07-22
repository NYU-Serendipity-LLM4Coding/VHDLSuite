-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-bit Shift Register Test
-- Generates random input and reset signals
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk       : in  std_logic;
    signal_in : out std_logic;
    resetn    : out std_logic;
    sim_done  : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator (replaces Verilog $random)
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random reset generator (matches Verilog: resetn <= ($random & 7) != 0)
    -- This creates resetn = '0' with probability ~1/8
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      sig <= '0' when (rand_int = 0) else '1';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= '0';
    resetn <= '1';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- First phase: repeat(100) @(posedge clk)
    for i in 1 to 100 loop
      wait until rising_edge(clk);
      random_bit(signal_in);
      random_reset(resetn);
    end loop;
    
    -- Second phase: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
      random_reset(resetn);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;