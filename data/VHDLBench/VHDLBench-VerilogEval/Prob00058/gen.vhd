-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for XOR Gate Test
-- Generates sequential test patterns followed by random tests
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
  signal inputs : std_logic_vector(1 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b}
  a <= inputs(1);
  b <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable count    : integer := 0;
    
    -- Random 2-bit vector generator
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
    
    wait for 10 ps;
    
    -- Matches Verilog: wavedrom_start("XOR gate");
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(10) @(posedge clk) {a,b} <= count++;
    for i in 1 to 10 loop
      wait until rising_edge(clk);
      inputs <= std_logic_vector(to_unsigned(count, 2));
      count := count + 1;
    end loop;
    
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk) {b,a} <= $urandom;
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
    
    wait;
  end process;

end architecture behavioral;