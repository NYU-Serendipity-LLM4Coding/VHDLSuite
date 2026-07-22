-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 8-bit Signed Adder with Overflow Detection
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(7 downto 0);
    b              : out std_logic_vector(7 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 16-bit concatenation {a, b}
  signal inputs : std_logic_vector(15 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a[7:0], b[7:0]}
  a <= inputs(15 downto 8);
  b <= inputs(7 downto 0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 16-bit test vector
    procedure apply_vector(vec : std_logic_vector(15 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 16-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 65536.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 16));
    end procedure;
    
  begin
    -- Initialize
    inputs <= (others => '0');
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- Matches Verilog: @(posedge clk) {a, b} <= 16'h...;
    
    wait until rising_edge(clk);
    apply_vector(x"0000");  -- 16'h0
    
    wait until rising_edge(clk);
    apply_vector(x"0070");  -- 16'h0070
    
    wait until rising_edge(clk);
    apply_vector(x"7070");  -- 16'h7070
    
    wait until rising_edge(clk);
    apply_vector(x"7090");  -- 16'h7090
    
    wait until rising_edge(clk);
    apply_vector(x"9070");  -- 16'h9070
    
    wait until rising_edge(clk);
    apply_vector(x"9090");  -- 16'h9090
    
    wait until rising_edge(clk);
    apply_vector(x"90FF");  -- 16'h90ff
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
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
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;