-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for FSM Circuit Test
-- Generates predetermined pattern followed by random inputs
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    x              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Wavedrom tasks (simplified)
    procedure wavedrom_start is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
  begin
    -- Initialize
    x <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_start;
    
    -- Predetermined test pattern
    -- Matches Verilog: @(posedge clk) x <= 2'h0; (repeated 4 times)
    wait until rising_edge(clk);
    x <= '0';
    
    wait until rising_edge(clk);
    x <= '0';
    
    wait until rising_edge(clk);
    x <= '0';
    
    wait until rising_edge(clk);
    x <= '0';
    
    -- Matches Verilog: @(posedge clk) x <= 2'h1; (repeated 4 times)
    wait until rising_edge(clk);
    x <= '1';
    
    wait until rising_edge(clk);
    x <= '1';
    
    wait until rising_edge(clk);
    x <= '1';
    
    wait until rising_edge(clk);
    x <= '1';
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- Random test: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(x);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;