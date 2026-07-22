-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Sequential Circuit Test
-- Generates predetermined and random test patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
  begin
    -- Initialize
    a <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- Matches Verilog: @(posedge clk) {a} <= 0;
    wait until rising_edge(clk);
    a <= '0';
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) {a} <= 0;
    wait until rising_edge(clk);
    a <= '0';
    
    -- Matches Verilog: repeat(10) @(posedge clk) a <= $urandom;
    for i in 1 to 10 loop
      wait until rising_edge(clk);
      random_bit(a);
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(a);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;