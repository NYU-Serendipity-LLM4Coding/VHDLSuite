-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Bit Relationship Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    tb_match       : in  boolean;
    signal_in      : out std_logic_vector(3 downto 0);
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
    
    -- Apply 4-bit test vector
    procedure apply_vector(vec : std_logic_vector(3 downto 0)) is
    begin
      signal_in <= vec;
    end procedure;
    
    -- Random 4-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      signal_in <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: in <= 4'h3;
    signal_in <= "0011";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- Matches Verilog sequence of @(posedge clk) in <= value;
    wait until rising_edge(clk);
    apply_vector("0011");  -- 3
    
    wait until rising_edge(clk);
    apply_vector("0110");  -- 6
    
    wait until rising_edge(clk);
    apply_vector("1100");  -- 12
    
    wait until rising_edge(clk);
    apply_vector("1001");  -- 9
    
    wait until rising_edge(clk);
    apply_vector("0101");  -- 5
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random value
    random_vector;
    
    -- Matches Verilog: repeat(100) begin @(negedge clk) ... @(posedge clk) ... end
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      random_vector;
      wait until rising_edge(clk);
      random_vector;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;