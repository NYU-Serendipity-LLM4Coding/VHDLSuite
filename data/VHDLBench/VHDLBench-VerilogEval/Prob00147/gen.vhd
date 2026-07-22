-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Sequential Circuit Test
-- Generates predetermined test pattern followed by random inputs
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
  signal ab_vector : std_logic_vector(1 downto 0);
begin

  -- Split vector to individual outputs
  -- ab_vector format: {a, b}
  a <= ab_vector(1);
  b <= ab_vector(0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 2-bit test vector {a, b}
    procedure apply_vector(vec : std_logic_vector(1 downto 0)) is
    begin
      ab_vector <= vec;
    end procedure;
    
    -- Random vector generator (matches Verilog: a <= &((5)'($urandom)))
    -- Note: Verilog reduction AND on random bits produces mostly 0s
    procedure random_a is
      variable bits : std_logic_vector(4 downto 0);
      variable result : std_logic;
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      bits := std_logic_vector(to_unsigned(rand_int, 5));
      -- Reduction AND: result = bits(4) and bits(3) and bits(2) and bits(1) and bits(0)
      result := bits(4) and bits(3) and bits(2) and bits(1) and bits(0);
      ab_vector(1) <= result;
      -- Keep b unchanged for this procedure
    end procedure;
    
  begin
    -- Initialize
    ab_vector <= "00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- Matches Verilog: a <= 1;
    ab_vector(1) <= '1';
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) {a,b} <= 0;
    wait until falling_edge(clk);
    apply_vector("00");
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- repeat(3) @(posedge clk); - no change to {a,b}, so just wait
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Now apply sequence of vectors at each posedge clk
    wait until rising_edge(clk);
    apply_vector("01");  -- {a,b} <= 1 (decimal 1 = binary 01)
    
    wait until rising_edge(clk);
    apply_vector("10");  -- {a,b} <= 2 (decimal 2 = binary 10)
    
    wait until rising_edge(clk);
    apply_vector("11");  -- {a,b} <= 3 (decimal 3 = binary 11)
    
    wait until rising_edge(clk);
    apply_vector("00");  -- {a,b} <= 0
    
    wait until rising_edge(clk);
    apply_vector("11");  -- {a,b} <= 3
    
    wait until rising_edge(clk);
    apply_vector("11");  -- {a,b} <= 3
    
    wait until rising_edge(clk);
    apply_vector("11");  -- {a,b} <= 3
    
    wait until rising_edge(clk);
    apply_vector("10");  -- {a,b} <= 2
    
    wait until rising_edge(clk);
    apply_vector("01");  -- {a,b} <= 1
    
    wait until rising_edge(clk);
    apply_vector("00");  -- {a,b} <= 0
    
    wait until rising_edge(clk);
    apply_vector("00");  -- {a,b} <= 0
    
    wait until rising_edge(clk);
    apply_vector("00");  -- {a,b} <= 0
    
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    -- Verilog only changes 'a', not 'b'
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_a;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;