-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for PS/2 Mouse Protocol FSM Test
-- Generates random 8-bit input data and reset signal
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    signal_in: out std_logic_vector(7 downto 0);
    reset    : out std_logic;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Generate random 8-bit value
    procedure random_byte(signal sig : out std_logic_vector(7 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
    -- Generate random reset (active approximately 1/32 of the time)
    -- Matches Verilog: reset <= !($random & 31);
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      -- Reset is active when random & 31 == 0
      sig <= '1' when rand_int = 0 else '0';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    reset <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(200) @(negedge clk)
    for i in 1 to 200 loop
      wait until falling_edge(clk);
      random_byte(signal_in);
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;