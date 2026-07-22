-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for JK Flip-Flop Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    j              : out std_logic;
    k              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 2-bit concatenation {j, k}
  signal jk_inputs : std_logic_vector(1 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- jk_inputs = {j, k}
  j <= jk_inputs(1);
  k <= jk_inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 2-bit test vector
    procedure apply_vector(vec : std_logic_vector(1 downto 0)) is
    begin
      jk_inputs <= vec;
    end procedure;
    
    -- Random 2-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      jk_inputs <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: {j,k} <= 1;
    jk_inputs <= "01";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog sequence)
    -- Matches Verilog: @(posedge clk) {j,k} <= 2'h1;
    wait until rising_edge(clk);
    apply_vector("01");  -- 2'h1
    
    wait until rising_edge(clk);
    apply_vector("10");  -- 2'h2
    
    wait until rising_edge(clk);
    apply_vector("11");  -- 2'h3
    
    wait until rising_edge(clk);
    apply_vector("11");  -- 2'h3
    
    wait until rising_edge(clk);
    apply_vector("11");  -- 2'h3
    
    wait until rising_edge(clk);
    apply_vector("00");  -- 2'h0
    
    wait until rising_edge(clk);
    apply_vector("00");  -- 2'h0
    
    wait until rising_edge(clk);
    apply_vector("00");  -- 2'h0
    
    wait until rising_edge(clk);
    apply_vector("10");  -- 2'h2
    
    wait until rising_edge(clk);
    apply_vector("10");  -- 2'h2
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
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