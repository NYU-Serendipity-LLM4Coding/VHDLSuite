-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Message Boundary FSM
-- Generates random test patterns with reset pulses, then deterministic message sequences
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
    
    -- Random 8-bit vector generator
    procedure random_byte(signal sig : out std_logic_vector(7 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    reset <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Phase 1: Random test with occasional resets
    -- Matches Verilog: repeat(200) @(negedge clk)
    for i in 1 to 200 loop
      wait until falling_edge(clk);
      random_byte(signal_in);
      
      -- Matches Verilog: reset <= !($random & 31);
      -- This creates random reset pulses (approximately 1 in 32 chance)
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      reset <= '1' when (rand_int = 0) else '0';
    end loop;
    
    -- Clear reset and input
    reset <= '0';
    signal_in <= (others => '0');
    
    -- Matches Verilog: repeat(10) @(posedge clk);
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Phase 2: Deterministic message sequences
    -- Matches Verilog: repeat(200) begin ... end
    -- Each iteration sends a 3-byte message with in[3]=1 for first byte
    for i in 1 to 200 loop
      -- Byte 1: in[3] must be '1'
      random_byte(signal_in);
      signal_in(3) <= '1';  -- Force bit 3 high
      wait until rising_edge(clk);
      
      -- Byte 2: random
      random_byte(signal_in);
      wait until rising_edge(clk);
      
      -- Byte 3: random
      random_byte(signal_in);
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;