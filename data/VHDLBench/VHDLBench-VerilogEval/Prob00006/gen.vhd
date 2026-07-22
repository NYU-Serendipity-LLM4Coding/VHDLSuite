-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Bit Reversal Test
-- Generates predetermined test vectors followed by random tests
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
    
    -- Random 8-bit vector generator
    procedure random_vector(signal sig : out std_logic_vector(7 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
  begin
    -- Initialize
    signal_in <= x"00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog sequence)
    wait until rising_edge(clk);
    signal_in <= x"01";  -- 8'h1
    
    wait until rising_edge(clk);
    signal_in <= x"02";  -- 8'h2
    
    wait until rising_edge(clk);
    signal_in <= x"04";  -- 8'h4
    
    wait until rising_edge(clk);
    signal_in <= x"08";  -- 8'h8
    
    wait until rising_edge(clk);
    signal_in <= x"80";  -- 8'h80
    
    wait until rising_edge(clk);
    signal_in <= x"C0";  -- 8'hc0
    
    wait until rising_edge(clk);
    signal_in <= x"E0";  -- 8'he0
    
    wait until rising_edge(clk);
    signal_in <= x"F0";  -- 8'hf0
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector(signal_in);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;