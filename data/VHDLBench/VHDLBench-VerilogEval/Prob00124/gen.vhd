-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Rule 110 Cellular Automaton Test
-- Loads various initial states and runs the automaton
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    load           : out std_logic;
    data           : out std_logic_vector(511 downto 0);
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
    
    -- Generate random 512-bit vector
    procedure random_vector(signal vec : out std_logic_vector(511 downto 0)) is
      variable temp : std_logic_vector(511 downto 0);
    begin
      for i in 0 to 511 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      vec <= temp;
    end procedure;
    
  begin
    -- Initialize
    data <= (others => '0');
    load <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Test 1: Load q[511:0] = 1 (only bit 0 set)
    data <= (0 => '1', others => '0');
    load <= '1';
    
    wait until rising_edge(clk);
    wavedrom_enable <= '1';  -- wavedrom_start
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    load <= '0';
    
    -- repeat(10) @(posedge clk)
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    
    wait for 1 ps;  -- wavedrom_stop
    wavedrom_enable <= '0';
    
    -- Test 2: Load bit 256
    data <= (256 => '1', others => '0');
    load <= '1';
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    load <= '0';
    
    -- repeat(1000) @(posedge clk)
    for i in 1 to 1000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Test 3: Load 512'h4df
    -- 0x4df = 1247 decimal, needs to be extended to 512 bits
    -- Using std_logic_vector conversion with resize
    data <= std_logic_vector(resize(unsigned'(x"4df"), 512));
    load <= '1';
    
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 1000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Test 4: Random data
    random_vector(data);
    load <= '1';
    
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 1000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Test 5: Zero then specific values
    data <= (others => '0');
    load <= '1';
    
    -- repeat(20) @(posedge clk)
    for i in 1 to 20 loop
      wait until rising_edge(clk);
    end loop;
    
    wait until rising_edge(clk);
    data <= std_logic_vector(resize(to_unsigned(2, 32), 512));
    
    wait until rising_edge(clk);
    data <= std_logic_vector(resize(to_unsigned(4, 32), 512));
    
    wait until rising_edge(clk);
    data <= std_logic_vector(resize(to_unsigned(9, 32), 512));
    load <= '0';
    
    wait until rising_edge(clk);
    data <= std_logic_vector(resize(to_unsigned(12, 32), 512));
    
    -- repeat(100) @(posedge clk)
    for i in 1 to 100 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;