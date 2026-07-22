-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 2-to-1 Mux Test
-- Provides predetermined test vectors followed by random tests
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
    sel_b1         : out std_logic;
    sel_b2         : out std_logic;
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
  -- inputs = {a, b, sel_b1, sel_b2}
  a      <= inputs(3);
  b      <= inputs(2);
  sel_b1 <= inputs(1);
  sel_b2 <= inputs(0);

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
    
    -- Random 4-bit vector generator (replaces Verilog $urandom)
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
    
    -- Initial delay
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog sequence)
    -- Vector format: {a, b, sel_b1, sel_b2}
    
    wait until rising_edge(clk);  -- First edge (posedge)
    apply_vector("0100");  -- 4'b0100
    
    wait until falling_edge(clk);  -- Second edge (negedge)
    apply_vector("1000");  -- 4'b1000
    
    wait until rising_edge(clk);
    apply_vector("1101");  -- 4'b1101
    
    wait until falling_edge(clk);
    apply_vector("0001");  -- 4'b0001
    
    wait until rising_edge(clk);
    apply_vector("0110");  -- 4'b0110
    
    wait until falling_edge(clk);
    apply_vector("1010");  -- 4'b1010
    
    wait until rising_edge(clk);
    apply_vector("1111");  -- 4'b1111
    
    wait until falling_edge(clk);
    apply_vector("0011");  -- 4'b0011
    
    wait until rising_edge(clk);
    apply_vector("0111");  -- 4'b0111
    
    wait until falling_edge(clk);
    apply_vector("1011");  -- 4'b1011
    
    wait until rising_edge(clk);
    apply_vector("1111");  -- 4'b1111
    
    wait until falling_edge(clk);
    apply_vector("0011");  -- 4'b0011
    
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
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;