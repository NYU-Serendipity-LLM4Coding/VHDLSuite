-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for D Flip-Flop Test
-- Generates random input on every clock edge
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    d              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  -- Matches Verilog: always @(posedge clk, negedge clk) d <= $urandom;
  random_d_process : process(clk)
    variable seed1    : positive := 123456;
    variable seed2    : positive := 789012;
    variable rand_val : real;
  begin
    if rising_edge(clk) or falling_edge(clk) then
      uniform(seed1, seed2, rand_val);
      d <= '1' when rand_val > 0.5 else '0';
    end if;
  end process;

  stimulus_process : process
  begin
    -- Initialize
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- Matches Verilog: @(posedge clk);
    wait until rising_edge(clk);
    
    -- Matches Verilog: wavedrom_start("Positive-edge triggered DFF");
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(10) @(posedge clk);
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk);
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;