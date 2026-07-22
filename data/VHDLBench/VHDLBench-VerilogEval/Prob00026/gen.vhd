-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for AND Gate Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic;
    b              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 2-bit concatenation {a, b}
  signal inputs : std_logic_vector(1 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b}
  a <= inputs(1);
  b <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    variable count    : integer;
    
    -- Apply 2-bit test vector
    procedure apply_vector(vec : std_logic_vector(1 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 2-bit vector generator (replaces Verilog $random)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "00";
    wavedrom_enable <= '0';
    sim_done <= false;
    count := 0;
    
    -- Initial delay
    wait for 10 ps;
    
    -- Matches Verilog: wavedrom_start("AND gate");
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog: repeat(10) @(posedge clk))
    -- count goes from 0 to 9, creating patterns 00, 01, 10, 11, 00, 01...
    for i in 0 to 9 loop
      wait until rising_edge(clk);
      apply_vector(std_logic_vector(to_unsigned(count, 2)));
      count := count + 1;
    end loop;
    
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    -- Note: Verilog assigns {b,a} but we maintain {a,b} order
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;