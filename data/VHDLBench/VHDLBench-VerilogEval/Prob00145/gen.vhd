-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Sequential Circuit Test
-- Generates clock divider and test patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    clock           : out std_logic;
    a               : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal clock_sig : std_logic := '0';
begin

  clock <= clock_sig;

  -- Clock divider process
  -- Matches Verilog: always begin repeat(3) @(posedge clk); clock = ~clock; end
  clock_gen : process
  begin
    loop
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      clock_sig <= not clock_sig;
    end loop;
  end process;

  -- Stimulus process
  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 12345;
    variable rand_val : real;
    
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
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clock) {a} <= 0;
    wait until falling_edge(clock_sig);
    a <= '0';
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) {a} <= 0;
    wait until rising_edge(clk);
    a <= '0';
    
    -- Matches Verilog: repeat(14) @(posedge clk,negedge clk) a <= ~a;
    for i in 1 to 14 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      a <= not a;
    end loop;
    
    -- Matches Verilog: repeat(5) @(posedge clk, negedge clk);
    for i in 1 to 5 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
    end loop;
    
    -- Matches Verilog: repeat(8) @(posedge clk,negedge clk) a <= ~a;
    for i in 1 to 8 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      a <= not a;
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk) a <= $urandom;
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(a);
    end loop;
    
    -- Signal completion
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;