-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 0-999 Counter Test
-- Tests synchronous reset and wrap-around behavior
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
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Helper procedure for random boolean
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 128.0));
      sig <= '1' when (rand_int = 0) else '0';
    end procedure;
    
    -- Reset test task (simplified version)
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
      
      -- Note: Warning messages omitted in VHDL version
    end procedure;
    
    -- Wavedrom tasks (simplified)
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
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Synchronous reset test
    wavedrom_start("Synchronous reset");
    reset_test;
    
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    reset <= '0';
    
    -- Wait for near wrap-around (989 negedge cycles)
    for i in 1 to 989 loop
      wait until falling_edge(clk);
    end loop;
    
    -- Wrap around behavior test
    wavedrom_start("Wrap around behaviour");
    for i in 1 to 14 loop
      wait until rising_edge(clk);
    end loop;
    wavedrom_stop;
    
    -- Random reset testing: repeat(2000) @(posedge clk, negedge clk)
    for i in 1 to 2000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_reset(reset);
    end loop;
    
    reset <= '0';
    
    -- Final cycles
    for i in 1 to 2000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;