-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Truth Table Circuit Test
-- Tests all 8 input combinations in sequence, then random values
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    x3             : out std_logic;
    x2             : out std_logic;
    x1             : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  -- Helper signal for 3-bit concatenation
  signal inputs : std_logic_vector(2 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {x3, x2, x1}
  x3 <= inputs(2);
  x2 <= inputs(1);
  x1 <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 3-bit test vector
    procedure apply_vector(vec : std_logic_vector(2 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 3-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: {x3, x2, x1} <= 3'h7;
    inputs <= "111";  -- 3'h7
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("All 8 input combinations");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(8) @(posedge clk) {x3, x2, x1} <= {x3, x2, x1} + 1'b1;
    -- Starting from 111 (7), incrementing 8 times: 0, 1, 2, 3, 4, 5, 6, 7
    for i in 0 to 7 loop
      wait until rising_edge(clk);
      inputs <= std_logic_vector(unsigned(inputs) + 1);
    end loop;
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(40) @(posedge clk, negedge clk);
    for i in 1 to 40 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
    end loop;
    
    -- Matches Verilog: {x3, x2, x1} <= $random;
    random_vector;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;