-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 16-bit Word Splitter Test
-- Generates random 16-bit input values on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic_vector(15 downto 0);
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
    
    -- Random 16-bit vector generator (replaces Verilog $random)
    procedure random_vector(signal sig : out std_logic_vector(15 downto 0)) is
    begin
      -- Generate random value for upper 16 bits
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 65536.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 16));
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start("Random inputs");
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(10) @(posedge clk);
    for i in 1 to 10 loop
      wait until rising_edge(clk);
      random_vector(signal_in);
    end loop;
    
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: repeat(100) @(negedge clk);
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      random_vector(signal_in);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;