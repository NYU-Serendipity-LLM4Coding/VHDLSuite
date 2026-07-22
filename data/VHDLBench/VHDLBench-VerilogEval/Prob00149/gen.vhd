-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Water Level FSM Test
-- Tests reset functionality and various water level transitions
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    reset           : out std_logic;
    s               : out std_logic_vector(3 downto 1);
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Array of sensor values (matches Verilog: wire [3:0][2:0] val)
  type val_array_t is array (0 to 3) of std_logic_vector(2 downto 0);
  constant val : val_array_t := (
    0 => "000",  -- val[0]
    1 => "001",  -- val[1]
    2 => "011",  -- val[2]
    3 => "111"   -- val[3]
  );
  
begin

  stimulus_process : process
    -- Local variables for random number generation (not shared)
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable sval     : integer := 0;
    variable rand_bit : std_logic;
    
    -- Random bit generator
    procedure random_bit(variable result : out std_logic) is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      if r > 0.5 then
        result := '1';
      else
        result := '0';
      end if;
    end procedure;
    
    -- Reset test task (simplified synchronous reset test)
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
    s <= "001";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Reset test
    reset_test;
    
    -- Predetermined test sequence
    wait until rising_edge(clk);
    s <= "000";
    
    wait until rising_edge(clk);
    s <= "000";
    
    -- Wavedrom start
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Test sequence: water rises to highest, then down to lowest
    wait until rising_edge(clk);
    s <= "000";
    
    wait until rising_edge(clk);
    s <= "001";
    
    wait until rising_edge(clk);
    s <= "011";
    
    wait until rising_edge(clk);
    s <= "111";
    
    wait until rising_edge(clk);
    s <= "111";
    
    wait until rising_edge(clk);
    s <= "011";
    
    wait until rising_edge(clk);
    s <= "011";
    
    wait until rising_edge(clk);
    s <= "001";
    
    wait until rising_edge(clk);
    s <= "001";
    
    wait until rising_edge(clk);
    s <= "000";
    
    wait until rising_edge(clk);
    s <= "000";
    
    -- Wavedrom stop
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(1000) with water level changes
    sval := 0;
    for i in 1 to 1000 loop
      -- Rise on posedge
      wait until rising_edge(clk);
      if sval < 3 then
        random_bit(rand_bit);
        if rand_bit = '1' then
          sval := sval + 1;
        end if;
      end if;
      s <= val(sval);
      
      -- Fall on negedge
      wait until falling_edge(clk);
      if sval > 0 then
        random_bit(rand_bit);
        if rand_bit = '1' then
          sval := sval - 1;
        end if;
      end if;
      s <= val(sval);
    end loop;
    
    -- Signal completion
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;