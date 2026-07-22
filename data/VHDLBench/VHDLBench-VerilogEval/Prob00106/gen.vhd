-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for PS/2 Scancode Decoder Test
-- Provides predetermined test vectors followed by random scancodes
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    scancode       : out std_logic_vector(15 downto 0);
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
    
    -- Random 16-bit vector generator
    procedure random_scancode is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 65536.0));
      scancode <= std_logic_vector(to_unsigned(rand_int, 16));
    end procedure;
    
  begin
    -- Initialize
    scancode <= x"0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- Initial delay
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Recognize arrow keys");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog sequence)
    wait until rising_edge(clk);
    scancode <= x"0000";  -- 16'h0
    
    wait until rising_edge(clk);
    scancode <= x"0001";  -- 16'h1
    
    wait until rising_edge(clk);
    scancode <= x"e075";  -- 16'he075 (up arrow)
    
    wait until rising_edge(clk);
    scancode <= x"e06b";  -- 16'he06b (left arrow)
    
    wait until rising_edge(clk);
    scancode <= x"e06c";  -- 16'he06c (not an arrow)
    
    wait until rising_edge(clk);
    scancode <= x"e072";  -- 16'he072 (down arrow)
    
    wait until rising_edge(clk);
    scancode <= x"e074";  -- 16'he074 (right arrow)
    
    wait until rising_edge(clk);
    scancode <= x"e076";  -- 16'he076 (not an arrow)
    
    wait until rising_edge(clk);
    scancode <= x"ffff";  -- 16'hffff
    
    -- Wavedrom stop
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(30000) @(posedge clk, negedge clk)
    for i in 1 to 30000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_scancode;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;