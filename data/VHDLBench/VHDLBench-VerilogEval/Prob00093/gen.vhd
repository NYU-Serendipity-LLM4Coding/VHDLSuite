-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for K-map MUX Implementation Test
-- Generates test vectors for inputs c and d
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    c              : out std_logic;
    d              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal cd : std_logic_vector(1 downto 0);
begin

  -- Split concatenated signal to individual outputs
  c <= cd(1);
  d <= cd(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 2-bit test vector
    procedure apply_vector(vec : std_logic_vector(1 downto 0)) is
    begin
      cd <= vec;
    end procedure;
    
    -- Random 2-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      cd <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
  begin
    -- Initialize
    cd <= "00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- Matches Verilog sequence
    wait until rising_edge(clk);
    apply_vector("00");  -- 2'h0
    
    wait until rising_edge(clk);
    apply_vector("01");  -- 2'h1
    
    wait until rising_edge(clk);
    apply_vector("10");  -- 2'h2
    
    wait until rising_edge(clk);
    apply_vector("11");  -- 2'h3
    
    -- Wavedrom stop
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(50) @(posedge clk, negedge clk)
    for i in 1 to 50 loop
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