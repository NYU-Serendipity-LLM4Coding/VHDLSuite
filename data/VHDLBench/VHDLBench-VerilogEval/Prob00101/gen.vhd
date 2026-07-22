-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Unknown Combinational Circuit Test
-- Generates sequential test pattern followed by random tests
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
  
  -- Helper signal for 4-bit concatenation {a,b,c,d}
  signal inputs : std_logic_vector(3 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, c, d}
  a <= inputs(3);
  b <= inputs(2);
  c <= inputs(1);
  d <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 4-bit test vector
    procedure apply_vector(vec : std_logic_vector(3 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 4-bit vector generator (replaces Verilog $urandom)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: {a,b,c,d} <= 0;
    inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) {a,b,c,d} <= 0;
    wait until rising_edge(clk);
    apply_vector("0000");
    
    -- Matches Verilog: repeat(18) @(posedge clk, negedge clk) {a,b,c,d} <= {a,b,c,d} + 1;
    -- This creates the sequential pattern from 0 to 18 (but only 0-15 are valid for 4 bits)
    for i in 1 to 18 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      -- Increment the 4-bit vector (wraps around at 16)
      inputs <= std_logic_vector(unsigned(inputs) + 1);
    end loop;
    
    -- Wavedrom stop
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test phase
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
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