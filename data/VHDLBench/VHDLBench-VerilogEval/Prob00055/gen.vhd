-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Minimum Finder Test
-- Provides predetermined test vectors followed by random tests
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
    c              : out std_logic_vector(7 downto 0);
    d              : out std_logic_vector(7 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 32-bit test vector to {a, b, c, d}
    procedure apply_vector(
      va : std_logic_vector(7 downto 0);
      vb : std_logic_vector(7 downto 0);
      vc : std_logic_vector(7 downto 0);
      vd : std_logic_vector(7 downto 0)
    ) is
    begin
      a <= va;
      b <= vb;
      c <= vc;
      d <= vd;
    end procedure;
    
    -- Random 32-bit vector generator (4 x 8-bit values)
    procedure random_vector is
      variable rand_a, rand_b, rand_c, rand_d : integer;
    begin
      uniform(seed1, seed2, rand_val);
      rand_a := integer(floor(rand_val * 256.0));
      uniform(seed1, seed2, rand_val);
      rand_b := integer(floor(rand_val * 256.0));
      uniform(seed1, seed2, rand_val);
      rand_c := integer(floor(rand_val * 256.0));
      uniform(seed1, seed2, rand_val);
      rand_d := integer(floor(rand_val * 256.0));
      
      a <= std_logic_vector(to_unsigned(rand_a, 8));
      b <= std_logic_vector(to_unsigned(rand_b, 8));
      c <= std_logic_vector(to_unsigned(rand_c, 8));
      d <= std_logic_vector(to_unsigned(rand_d, 8));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: {a,b,c,d} <= {8'h1, 8'h2, 8'h3, 8'h4};
    apply_vector(x"01", x"02", x"03", x"04");
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk); wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- Matches Verilog sequence
    
    wait until rising_edge(clk);
    apply_vector(x"01", x"02", x"03", x"04");  -- {8'h1, 8'h2, 8'h3, 8'h4}
    
    wait until rising_edge(clk);
    apply_vector(x"11", x"02", x"03", x"04");  -- {8'h11, 8'h2, 8'h3, 8'h4}
    
    wait until rising_edge(clk);
    apply_vector(x"11", x"12", x"03", x"04");  -- {8'h11, 8'h12, 8'h3, 8'h4}
    
    wait until rising_edge(clk);
    apply_vector(x"11", x"12", x"13", x"04");  -- {8'h11, 8'h12, 8'h13, 8'h4}
    
    wait until rising_edge(clk);
    apply_vector(x"11", x"12", x"13", x"14");  -- {8'h11, 8'h12, 8'h13, 8'h14}
    
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