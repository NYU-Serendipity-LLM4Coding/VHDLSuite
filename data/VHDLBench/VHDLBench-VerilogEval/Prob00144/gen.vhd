-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Conway's Game of Life
-- Generates test patterns: blinker, glider, acorn, and random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    tb_match : in  boolean;
    q_ref    : in  std_logic_vector(255 downto 0);
    q_dut    : in  std_logic_vector(255 downto 0);
    load     : out std_logic;
    data     : out std_logic_vector(255 downto 0);
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1 : positive := 12345;
    variable seed2 : positive := 67890;
    variable rand_val : real;
    variable errored : boolean;
    variable blinker_cycle : integer;
    variable temp_data : std_logic_vector(255 downto 0);
    
    -- Random 256-bit vector generator
    impure function random_256 return std_logic_vector is
      variable temp : std_logic_vector(255 downto 0);
    begin
      for i in 0 to 255 loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      return temp;
    end function;
    
    -- Random with AND reduction (more zeros)
    impure function random_256_sparse return std_logic_vector is
    begin
      return random_256 and random_256 and random_256 and random_256;
    end function;
    
  begin
    -- Initialize
    load <= '0';
    data <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;
    
    -----------------------------------------------------------------------------
    -- Test 1: Simple blinker (period 2), initial state = 256'h7
    -----------------------------------------------------------------------------
    temp_data := (others => '0');
    temp_data(2 downto 0) := "111";  -- 0x7
    data <= temp_data;
    load <= '1';
    wait until rising_edge(clk);
    load <= '0';
    data <= (others => 'X');
    
    errored := false;
    blinker_cycle := 0;
    
    for i in 1 to 5 loop
      wait until rising_edge(clk);
      blinker_cycle := blinker_cycle + 1;
      
      if not tb_match then
        if not errored then
          errored := true;
          report "Hint: Blinker test, first mismatch at cycle " & integer'image(blinker_cycle) severity note;
        end if;
      end if;
    end loop;
    
    -----------------------------------------------------------------------------
    -- Test 2: Glider, initial state = 256'h000200010007
    -----------------------------------------------------------------------------
    temp_data := (others => '0');
    temp_data(2 downto 0) := "111";   -- 0x7
    temp_data(16) := '1';              -- 0x10000
    temp_data(33) := '1';              -- 0x200000000
    data <= temp_data;
    
    load <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    load <= '0';
    data <= (others => 'X');
    
    errored := false;
    blinker_cycle := 0;
    
    for i in 1 to 100 loop
      wait until rising_edge(clk);
      blinker_cycle := blinker_cycle + 1;
      
      if not tb_match then
        if not errored then
          errored := true;
          report "Hint: Glider test, first mismatch at cycle " & integer'image(blinker_cycle) severity note;
        end if;
      end if;
    end loop;
    
    -----------------------------------------------------------------------------
    -- Test 3: Acorn, initial state = 256'h0040001000ce
    -----------------------------------------------------------------------------
    temp_data := (others => '0');
    temp_data(7 downto 1) := "1100111";  -- 0xCE
    temp_data(12) := '1';                 -- 0x1000
    temp_data(30) := '1';                 -- 0x40000000
    data <= temp_data;
    
    load <= '1';
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 2000 loop
      wait until rising_edge(clk);
    end loop;
    
    -----------------------------------------------------------------------------
    -- Test 4: Random test case
    -----------------------------------------------------------------------------
    data <= random_256;
    load <= '1';
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 200 loop
      wait until rising_edge(clk);
    end loop;
    
    -----------------------------------------------------------------------------
    -- Test 5: Random with more zeros (sparse)
    -----------------------------------------------------------------------------
    data <= random_256_sparse;
    load <= '1';
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 200 loop
      wait until rising_edge(clk);
    end loop;
    
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;