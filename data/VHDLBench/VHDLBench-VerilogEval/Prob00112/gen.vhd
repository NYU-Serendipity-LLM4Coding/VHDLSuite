-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-bit Priority Encoder Test
-- Generates test patterns: shift patterns, sequential, and random
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
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
    variable temp_vec : unsigned(3 downto 0);
    
    -- Random 4-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      signal_in <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    signal_in <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Priority encoder");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) in <= 4'h1;
    wait until rising_edge(clk);
    signal_in <= "0001";  -- 4'h1
    
    -- Matches Verilog: repeat(4) @(posedge clk) in <= in << 1;
    for i in 1 to 4 loop
      wait until rising_edge(clk);
      temp_vec := unsigned(signal_in);
      temp_vec := shift_left(temp_vec, 1);
      signal_in <= std_logic_vector(temp_vec);
    end loop;
    
    -- Matches Verilog: in <= 0;
    signal_in <= "0000";
    
    -- Matches Verilog: repeat(16) @(posedge clk) in <= in + 1;
    for i in 1 to 16 loop
      wait until rising_edge(clk);
      temp_vec := unsigned(signal_in);
      temp_vec := temp_vec + 1;
      signal_in <= std_logic_vector(temp_vec);
    end loop;
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(50) @(posedge clk, negedge clk)
    for i in 1 to 50 loop
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