-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Moore FSM Test
-- Generates input and reset sequences for state machine testing
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    signal_in       : out std_logic;
    areset          : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic := '1';
begin

  areset <= reset;

  stimulus_process : process
    variable seed1    : positive := 123;
    variable seed2    : positive := 456;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random reset generator (matches Verilog: !($random & 31))
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '0' when (rand_int /= 0) else '1';
    end procedure;
    
    -- Reset test procedure (simplified from Verilog task)
    procedure reset_test is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      reset <= '1';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    signal_in <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial sequence
    wait until rising_edge(clk);
    reset <= '0';
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    -- Wavedrom section
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    -- No change to signal_in
    
    wait until falling_edge(clk);
    reset <= '1';
    
    wait until rising_edge(clk);
    reset <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until falling_edge(clk);
    wavedrom_enable <= '0';
    
    wait for 1 ps;
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;