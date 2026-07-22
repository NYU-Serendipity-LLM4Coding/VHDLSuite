-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Population Count Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic_vector(2 downto 0);
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
    variable in_val   : unsigned(2 downto 0);
    
    -- Random 3-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      signal_in <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: in <= 7;
    signal_in <= "111";  -- 7 in binary
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Start wavedrom
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(9) @(posedge clk) in <= in + 1'b1;
    -- Starting from 7, increment 9 times: 7, 0, 1, 2, 3, 4, 5, 6, 7 (wraps at 8)
    in_val := "111";  -- Start at 7
    for i in 1 to 9 loop
      wait until rising_edge(clk);
      in_val := in_val + 1;
      signal_in <= std_logic_vector(in_val);
    end loop;
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Stop wavedrom
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
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