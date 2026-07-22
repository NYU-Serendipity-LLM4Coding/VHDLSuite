-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for AND-OR-NOT Circuit Test
-- Provides exhaustive test followed by random tests
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
  -- inputs = {d, c, b, a} (matches Verilog bit ordering)
  d <= inputs(3);
  c <= inputs(2);
  b <= inputs(1);
  a <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
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
    -- Matches Verilog: {a,b,c,d} = 4'h0;
    inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Matches Verilog: wavedrom_start("Exhaustive test");
    wavedrom_enable <= '1';
    
    -- Exhaustive test: repeat(20) @(posedge clk, negedge clk)
    -- Matches Verilog: {d,c,b,a} <= {d,c,b,a} + 1'b1;
    for i in 0 to 19 loop
      if (i mod 2) = 0 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      inputs <= std_logic_vector(unsigned(inputs) + 1);
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
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