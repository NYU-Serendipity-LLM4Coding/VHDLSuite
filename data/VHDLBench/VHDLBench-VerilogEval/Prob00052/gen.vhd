-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 100-input Reduction Gates Test
-- Provides predetermined test vectors followed by random and systematic tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    tb_match        : in  boolean;
    signal_in       : out std_logic_vector(99 downto 0);
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable count    : unsigned(3 downto 0) := (others => '0');
    variable temp_vec : std_logic_vector(99 downto 0);
    
    -- Random 100-bit vector generator
    procedure random_vector is
      variable temp : std_logic_vector(99 downto 0);
    begin
      for i in 0 to 99 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      signal_in <= temp;
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    wavedrom_enable <= '0';
    sim_done <= false;
    count := (others => '0');
    
    wait for 10 ps;
    
    -- Test AND gate section
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    signal_in <= (others => '0');  -- 100'h0
    
    wait until falling_edge(clk);
    signal_in <= (others => '1');  -- ~100'h0
    
    wait until rising_edge(clk);
    -- 100'h3ffff = 18 bits set (bits 17:0)
    signal_in <= (17 downto 0 => '1', others => '0');
    
    wait until falling_edge(clk);
    signal_in <= (17 downto 0 => '0', others => '1');  -- ~100'h3ffff
    
    wait until rising_edge(clk);
    -- 100'h80 = bit 7 set
    signal_in <= (7 => '1', others => '0');
    
    wait until falling_edge(clk);
    signal_in <= (7 => '0', others => '1');  -- ~100'h80
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Test OR and XOR gates section
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    signal_in <= (others => '0');  -- Test OR gate
    
    wait until rising_edge(clk);
    signal_in <= (2 downto 0 => '1', others => '0');  -- 100'h7
    
    -- repeat(10) @(posedge clk, negedge clk)
    for i in 1 to 10 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      signal_in <= std_logic_vector(resize(count, 100));
      count := count + 1;
    end loop;
    
    wait until rising_edge(clk);
    signal_in <= (others => '0');
    
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random tests: repeat(100)
    random_vector;
    for i in 1 to 100 loop
      wait until falling_edge(clk);
      random_vector;
      wait until rising_edge(clk);
      random_vector;
    end loop;
    
    -- Systematic bit tests: for (int i=0;i<100;i++)
    -- CRITICAL FIX: Use temporary variable to build vector with non-static index
    for i in 0 to 99 loop
      wait until falling_edge(clk);
      -- Build vector: 100'h1<<i (only bit i is set)
      temp_vec := (others => '0');
      temp_vec(i) := '1';
      signal_in <= temp_vec;
      
      wait until rising_edge(clk);
      -- Build vector: ~(100'h1<<i) (all bits except i are set)
      temp_vec := (others => '1');
      temp_vec(i) := '0';
      signal_in <= temp_vec;
    end loop;
    
    -- Final tests
    wait until rising_edge(clk);
    signal_in <= (others => '0');  -- Test OR gate
    
    wait until rising_edge(clk);
    signal_in <= (others => '1');  -- Test AND gate
    
    wait until rising_edge(clk);
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;