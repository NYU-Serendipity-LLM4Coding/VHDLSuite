-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Galois LFSR Test
-- Tests reset functionality and generates random reset patterns
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
    variable arfail   : boolean;
    variable srfail   : boolean;
    variable datafail : boolean;
    
    -- Reset test procedure (matches Verilog task reset_test)
    procedure reset_test is
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
      
      -- Note: Display messages omitted in VHDL (would use report/assert)
    end procedure;
    
    -- Wavedrom procedures (simplified)
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
    
    -- Matches Verilog: @(negedge clk)
    wait until falling_edge(clk);
    
    wavedrom_start;
    
    -- Reset test
    reset_test;
    
    -- repeat(8) @(posedge clk)
    for i in 1 to 8 loop
      wait until rising_edge(clk);
    end loop;
    
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- Random reset pattern: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Matches Verilog: reset <= !($random & 31)
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      reset <= '0' when (rand_int /= 0) else '1';
    end loop;
    
    -- @(posedge clk) reset <= 1'b0
    wait until rising_edge(clk);
    reset <= '0';
    
    -- repeat(2000) @(posedge clk)
    for i in 1 to 2000 loop
      wait until rising_edge(clk);
    end loop;
    
    reset <= '1';
    
    -- repeat(5) @(posedge clk)
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: #1 $finish
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;