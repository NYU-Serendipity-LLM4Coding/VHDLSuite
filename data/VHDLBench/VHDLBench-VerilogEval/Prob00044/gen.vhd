-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Bitwise/Logical OR and NOT operations
-- Generates sequential test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(2 downto 0);
    b              : out std_logic_vector(2 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal inputs : std_logic_vector(5 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {b, a}
  b <= inputs(5 downto 3);
  a <= inputs(2 downto 0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable count    : integer;
    
    -- Apply 6-bit test vector
    procedure apply_vector(vec : std_logic_vector(5 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 6-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 64.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 6));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: int count; count = 6'h38;
    count := 16#38#;  -- 6'h38 = 56 decimal
    
    -- Matches Verilog: {b, a} <= 6'b0;
    inputs <= "000000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Matches Verilog: wavedrom_start();
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(30) @(posedge clk) {b, a} <= count++;
    for i in 1 to 30 loop
      wait until rising_edge(clk);
      inputs <= std_logic_vector(to_unsigned(count, 6));
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
      random_vector;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;