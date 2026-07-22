-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Vector Concatenation Test
-- Generates predetermined and random test vectors
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(4 downto 0);
    b              : out std_logic_vector(4 downto 0);
    c              : out std_logic_vector(4 downto 0);
    d              : out std_logic_vector(4 downto 0);
    e              : out std_logic_vector(4 downto 0);
    f              : out std_logic_vector(4 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  -- Helper signal for 30-bit concatenation {a,b,c,d,e,f}
  signal inputs : std_logic_vector(29 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a[4:0], b[4:0], c[4:0], d[4:0], e[4:0], f[4:0]}
  a <= inputs(29 downto 25);
  b <= inputs(24 downto 20);
  c <= inputs(19 downto 15);
  d <= inputs(14 downto 10);
  e <= inputs(9 downto 5);
  f <= inputs(4 downto 0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 30-bit test vector
    procedure apply_vector(vec : std_logic_vector(29 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 30-bit vector generator
    procedure random_vector is
      variable rand_bits : std_logic_vector(29 downto 0);
    begin
      for i in 0 to 29 loop
        uniform(seed1, seed2, rand_val);
        rand_bits(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      inputs <= rand_bits;
    end procedure;
    
  begin
    -- Initialize
    inputs <= (others => '0');
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: wavedrom_start("");
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- Matches Verilog: @(posedge clk) {a,b,c,d,e,f} <= value;
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(0, 30)));  -- '0
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(1, 30)));  -- 1
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(2, 30)));  -- 2
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(4, 30)));  -- 4
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(8, 30)));  -- 8
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#10#, 30)));  -- 'h10
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#20#, 30)));  -- 'h20
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#40#, 30)));  -- 'h40
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#80#, 30)));  -- 'h80
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#100#, 30)));  -- 'h100
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#200#, 30)));  -- 'h200
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(16#400#, 30)));  -- 'h400
    
    wait until rising_edge(clk);
    -- Matches Verilog: {5'h1f, 5'h0, 5'h1f, 5'h0, 5'h1f, 5'h0}
    -- = "11111" & "00000" & "11111" & "00000" & "11111" & "00000"
    apply_vector("111110000011111000001111100000");
    
    -- Matches Verilog: @(negedge clk); wavedrom_stop();
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