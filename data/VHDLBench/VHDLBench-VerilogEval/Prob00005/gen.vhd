-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for NOT Gate Test
-- Generates random input signals on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic;
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
    
    -- Random bit generator (replaces Verilog $random)
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Wavedrom tasks (simplified, not functional in VHDL)
    procedure wavedrom_start(title : string) is
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
    signal_in <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start("Inversion");
    wavedrom_start("Inversion");
    
    -- Matches Verilog: repeat(20) @(posedge clk)
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      random_bit(signal_in);
    end loop;
    
    wavedrom_stop;
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;