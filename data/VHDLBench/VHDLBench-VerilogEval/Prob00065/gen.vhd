-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 7420 Dual 4-input NAND Gate Test
-- Generates sequential test patterns followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    p1a            : out std_logic;
    p1b            : out std_logic;
    p1c            : out std_logic;
    p1d            : out std_logic;
    p2a            : out std_logic;
    p2b            : out std_logic;
    p2c            : out std_logic;
    p2d            : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signals for 4-bit groups
  signal p1_inputs : std_logic_vector(3 downto 0);
  signal p2_inputs : std_logic_vector(3 downto 0);
  
begin

  -- Split concatenated signals to individual outputs
  -- p1_inputs = {p1a, p1b, p1c, p1d}
  p1a <= p1_inputs(3);
  p1b <= p1_inputs(2);
  p1c <= p1_inputs(1);
  p1d <= p1_inputs(0);
  
  -- p2_inputs = {p2a, p2b, p2c, p2d}
  p2a <= p2_inputs(3);
  p2b <= p2_inputs(2);
  p2c <= p2_inputs(1);
  p2d <= p2_inputs(0);

  stimulus_process : process
    variable count    : integer := 0;
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply test vectors to both groups
    procedure apply_vectors(vec1, vec2 : std_logic_vector(3 downto 0)) is
    begin
      p1_inputs <= vec1;
      p2_inputs <= vec2;
    end procedure;
    
    -- Random 8-bit vector generator
    procedure random_vectors is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      p1_inputs <= std_logic_vector(to_unsigned(rand_int mod 16, 4));
      p2_inputs <= std_logic_vector(to_unsigned(rand_int / 16, 4));
    end procedure;
    
  begin
    -- Initialize
    p1_inputs <= "0000";
    p2_inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    count := 0;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start("Two NAND gates");
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(20) @(posedge clk)
    for i in 0 to 19 loop
      wait until rising_edge(clk);
      -- {p1a,p1b,p1c,p1d} <= count;
      -- {p2a,p2b,p2c,p2d} <= count+1;
      apply_vectors(
        std_logic_vector(to_unsigned(count, 4)),
        std_logic_vector(to_unsigned(count + 1, 4))
      );
      count := count + 1;
    end loop;
    
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vectors;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;