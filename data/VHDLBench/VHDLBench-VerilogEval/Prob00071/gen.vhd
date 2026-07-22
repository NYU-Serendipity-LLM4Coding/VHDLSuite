-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Priority Encoder Test
-- Generates predetermined test patterns followed by random and sequential tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic_vector(7 downto 0);
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
    variable in_vec   : unsigned(7 downto 0);
    
    -- Random 8-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      signal_in <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
  begin
    -- Initialize
    signal_in <= x"00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Priority encoder");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- First pattern: shift left starting from 0x01
    -- @(posedge clk) in <= 8'h1;
    wait until rising_edge(clk);
    signal_in <= x"01";
    in_vec := x"01";
    
    -- repeat(8) @(posedge clk) in <= in << 1;
    for i in 1 to 8 loop
      wait until rising_edge(clk);
      in_vec := shift_left(in_vec, 1);
      signal_in <= std_logic_vector(in_vec);
    end loop;
    
    -- in <= 8'h10;
    signal_in <= x"10";
    in_vec := x"10";
    
    -- repeat(8) @(posedge clk) in <= in + 1;
    for i in 1 to 8 loop
      wait until rising_edge(clk);
      in_vec := in_vec + 1;
      signal_in <= std_logic_vector(in_vec);
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
    
    -- Sequential test: repeat(260) @(posedge clk, negedge clk) in <= in + 1;
    -- Start from current value
    in_vec := unsigned(signal_in);
    for i in 1 to 260 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      in_vec := in_vec + 1;
      signal_in <= std_logic_vector(in_vec);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;