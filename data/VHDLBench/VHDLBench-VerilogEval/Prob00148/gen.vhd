-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for FSM Arbiter Test
-- Generates reset sequence and random test patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    resetn          : out std_logic;
    r               : out std_logic_vector(3 downto 1);
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic := '1';
begin

  -- Matches Verilog: assign resetn = ~reset;
  resetn <= not reset;

  stimulus_process : process
    variable seed1    : positive := 123456;
    variable seed2    : positive := 789012;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 3-bit vector generator
    procedure random_r is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      r <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
    -- Random boolean (for reset generation)
    function random_bool return boolean is
      variable rval : real;
      variable rint : integer;
    begin
      uniform(seed1, seed2, rval);
      rint := integer(floor(rval * 64.0));
      return (rint = 0);
    end function;
    
    -- Reset test task (simplified from Verilog version)
    procedure reset_test is
      variable datafail, arfail, srfail : boolean;
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      -- Warning messages (optional in VHDL, could use report statements)
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    r <= "000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait until rising_edge(clk);
    
    -- Matches Verilog: r <= 1; reset_test();
    r <= "001";
    reset_test;
    
    -- Wavedrom section with predetermined patterns
    r <= "000";
    wait until rising_edge(clk);
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    r <= "000";
    
    wait until rising_edge(clk);
    r <= "111";  -- 7
    
    wait until rising_edge(clk);
    r <= "111";  -- 7
    
    wait until rising_edge(clk);
    r <= "111";  -- 7
    
    wait until rising_edge(clk);
    r <= "110";  -- 6
    
    wait until rising_edge(clk);
    r <= "110";  -- 6
    
    wait until rising_edge(clk);
    r <= "110";  -- 6
    
    wait until rising_edge(clk);
    r <= "100";  -- 4
    
    wait until rising_edge(clk);
    r <= "100";  -- 4
    
    wait until rising_edge(clk);
    r <= "100";  -- 4
    
    wait until rising_edge(clk);
    r <= "000";  -- 0
    
    wait until rising_edge(clk);
    r <= "000";  -- 0
    
    wait until rising_edge(clk);
    r <= "100";  -- 4
    
    wait until rising_edge(clk);
    r <= "110";  -- 6
    
    wait until rising_edge(clk);
    r <= "111";  -- 7
    
    wait until rising_edge(clk);
    r <= "111";  -- 7
    
    wait until rising_edge(clk);
    r <= "111";  -- 7
    
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Additional reset sequence
    wait until rising_edge(clk);
    reset <= '0';
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Random test: repeat(500) @(negedge clk)
    for i in 1 to 500 loop
      wait until falling_edge(clk);
      reset <= '1' when random_bool else '0';
      random_r;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;