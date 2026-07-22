-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Decade Counter Test
-- Tests synchronous reset and counting behavior
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    reset           : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Task: reset_test (simplified version)
    procedure reset_test is
      variable arfail, srfail, datafail : boolean;
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      -- Note: Display hints not implemented in VHDL version
      -- Original Verilog has $display statements here
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
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start("Synchronous reset and counting");
    wavedrom_start;
    
    -- Matches Verilog: reset_test();
    reset_test;
    
    -- Matches Verilog: repeat(12) @(posedge clk);
    for i in 1 to 12 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    wait until rising_edge(clk);
    
    -- Matches Verilog: repeat(400) @(posedge clk, negedge clk)
    -- with random reset generation
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Matches Verilog: reset <= !($random & 31);
      -- Generate random number, AND with 31, then invert
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      if (rand_int mod 32) = 0 then
        reset <= '1';
      else
        reset <= '0';
      end if;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;