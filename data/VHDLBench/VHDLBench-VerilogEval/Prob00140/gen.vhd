-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for HDLC Framing FSM Test
-- Generates random reset and input signals
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    reset    : out std_logic;
    signal_in: out std_logic;
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
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random bit with probability (~1/8 chance of being 1)
    -- Matches Verilog: |($random&7)
    procedure random_bit_sparse(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      sig <= '1' when rand_int /= 0 else '0';
    end procedure;
    
    -- Random reset with low probability
    -- Matches Verilog: !($random & 31)
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '1' when rand_int = 0 else '0';
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: reset <= 1; in <= 0;
    reset <= '1';
    signal_in <= '0';
    sim_done <= false;
    
    -- Wait for first clock edge
    -- Matches Verilog: @(posedge clk);
    wait until rising_edge(clk);
    
    -- Main test loop
    -- Matches Verilog: repeat(800) @(posedge clk, negedge clk)
    for i in 1 to 800 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      random_reset(reset);
      random_bit_sparse(signal_in);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;