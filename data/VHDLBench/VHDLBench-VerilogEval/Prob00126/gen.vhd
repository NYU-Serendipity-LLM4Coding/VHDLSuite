-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Combinational Lookup Table Test
-- Generates sequential and random test patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(2 downto 0);
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
    variable rand_int : integer;
    variable a_int    : integer := 0;
    
    -- Random 3-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));  -- 0 to 7
      a <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize
    a <= "000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) {a} <= 0;
    wait until rising_edge(clk);
    a <= "000";
    a_int := 0;
    
    -- Matches Verilog: repeat(10) @(posedge clk, negedge clk) a <= a + 1;
    -- This is 10 clock edges (5 rising + 5 falling), incrementing on each edge
    for i in 1 to 10 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      a_int := a_int + 1;
      a <= std_logic_vector(to_unsigned(a_int mod 8, 3));
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk) a <= $urandom;
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;