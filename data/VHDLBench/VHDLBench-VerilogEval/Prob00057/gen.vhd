-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Karnaugh Map Circuit Test
-- Generates sequential test vectors followed by random tests
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
    d              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 4-bit concatenation
  signal inputs : std_logic_vector(3 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, c, d}
  a <= inputs(3);
  b <= inputs(2);
  c <= inputs(1);
  d <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable count    : integer;
    
    -- Apply 4-bit test vector
    procedure apply_vector(vec : std_logic_vector(3 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 4-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    count := 0;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start();
    wavedrom_enable <= '1';
    
    -- Sequential test: repeat(16) @(posedge clk) {a,b,c,d} <= count++;
    for i in 0 to 15 loop
      wait until rising_edge(clk);
      inputs <= std_logic_vector(to_unsigned(count, 4));
      count := count + 1;
    end loop;
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    -- Note: Verilog assigns to {d,c,b,a} (reversed order)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
      -- Verilog uses {d,c,b,a} <= $urandom, so we need to reverse the order
      -- But since our random_vector generates random bits anyway, order doesn't matter
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;