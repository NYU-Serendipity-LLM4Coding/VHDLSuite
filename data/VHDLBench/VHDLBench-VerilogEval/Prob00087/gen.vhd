-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Logic Gates Test
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
  
  -- Helper signal for 2-bit concatenation
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
    
    -- Apply 2-bit test vector
    procedure apply_vector(vec : std_logic_vector(1 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
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
    
    -- Matches Verilog: @(negedge clk) {a,b} <= 0;
    wait until falling_edge(clk);
    apply_vector("00");
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (exhaustive for 2 inputs)
    wait until rising_edge(clk);
    apply_vector("00");  -- 0
    
    wait until rising_edge(clk);
    apply_vector("01");  -- 1
    
    wait until rising_edge(clk);
    apply_vector("10");  -- 2
    
    wait until rising_edge(clk);
    apply_vector("11");  -- 3
    
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
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