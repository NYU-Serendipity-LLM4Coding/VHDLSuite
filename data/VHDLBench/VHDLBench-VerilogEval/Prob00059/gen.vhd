-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Wire Connection Test
-- Generates random input signals on clock edges
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
    c              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 3-bit concatenation
  signal inputs : std_logic_vector(2 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, c}
  a <= inputs(2);
  b <= inputs(1);
  c <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 3-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: always @(posedge clk, negedge clk) {a,b,c} <= $random;
    -- This runs continuously, but we'll start it after first negedge
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(8) @(posedge clk);
    for i in 1 to 8 loop
      wait until rising_edge(clk);
      random_vector;
    end loop;
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(100) @(negedge clk);
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      random_vector;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- Continuous random generation on clock edges
  -- Matches Verilog: always @(posedge clk, negedge clk) {a,b,c} <= $random;
  random_process : process(clk)
    variable seed1    : positive := 99999;
    variable seed2    : positive := 44444;
    variable rand_val : real;
    variable rand_int : integer;
  begin
    if rising_edge(clk) or falling_edge(clk) then
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 3));
    end if;
  end process;

end architecture behavioral;