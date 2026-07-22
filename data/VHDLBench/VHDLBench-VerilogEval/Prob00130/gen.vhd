-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-to-1 Multiplexer Test
-- Generates predetermined test patterns followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(3 downto 0);
    b              : out std_logic_vector(3 downto 0);
    c              : out std_logic_vector(3 downto 0);
    d              : out std_logic_vector(3 downto 0);
    e              : out std_logic_vector(3 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for concatenation {a,b,c,d,e}
  signal inputs : std_logic_vector(19 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a(3:0), b(3:0), c(3:0), d(3:0), e(3:0)}
  a <= inputs(19 downto 16);
  b <= inputs(15 downto 12);
  c <= inputs(11 downto 8);
  d <= inputs(7 downto 4);
  e <= inputs(3 downto 0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable c_val    : unsigned(3 downto 0);
    
    -- Apply 20-bit test vector
    procedure apply_vector(vec : std_logic_vector(19 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 20-bit vector generator
    procedure random_vector is
      variable rand_bits : std_logic_vector(19 downto 0);
    begin
      for i in 0 to 19 loop
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
    
    wait for 10 ps;  -- Initial delay
    
    -- First wavedrom section
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) {a,b,c,d,e} <= {20'hab0de};
    wait until rising_edge(clk);
    apply_vector(x"ab0de");  -- 20-bit hex value
    
    -- Matches Verilog: repeat(18) @(posedge clk, negedge clk) c <= c + 1;
    for i in 1 to 18 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      c_val := unsigned(inputs(11 downto 8));
      c_val := c_val + 1;
      inputs(11 downto 8) <= std_logic_vector(c_val);
    end loop;
    
    -- wavedrom_stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Second wavedrom section
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) {a,b,c,d,e} <= {20'h12034};
    wait until rising_edge(clk);
    apply_vector(x"12034");
    
    -- Matches Verilog: repeat(8) @(posedge clk, negedge clk) c <= c + 1;
    for i in 1 to 8 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      c_val := unsigned(inputs(11 downto 8));
      c_val := c_val + 1;
      inputs(11 downto 8) <= std_logic_vector(c_val);
    end loop;
    
    -- Matches Verilog: @(posedge clk) {a,b,c,d,e} <= {20'h56078};
    wait until rising_edge(clk);
    apply_vector(x"56078");
    
    -- Matches Verilog: repeat(8) @(posedge clk, negedge clk) c <= c + 1;
    for i in 1 to 8 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      c_val := unsigned(inputs(11 downto 8));
      c_val := c_val + 1;
      inputs(11 downto 8) <= std_logic_vector(c_val);
    end loop;
    
    -- wavedrom_stop
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