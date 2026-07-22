-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 2's Complement Moore FSM Test
-- Generates reset and input test patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    x               : out std_logic;
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
    
    -- Random integer 0-31
    function random_int_0_31 return integer is
      variable rval : real;
    begin
      uniform(seed1, seed2, rval);
      return integer(floor(rval * 32.0));
    end function;
    
    -- Reset test task (simplified version)
    procedure reset_test(async : boolean) is
      variable arfail, srfail, datafail : boolean;
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
      
      if srfail then
        report "Hint: Your reset doesn't seem to be working." severity note;
      elsif arfail and (async or not datafail) then
        if async then
          report "Hint: Your reset should be asynchronous, but doesn't appear to be." severity note;
        else
          report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
        end if;
      end if;
    end procedure;
    
  begin
    -- Initialize
    x <= '0';
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial sequence
    wait until rising_edge(clk);
    reset <= '0';
    x <= '1';
    
    wait until rising_edge(clk);
    x <= '0';
    
    -- Reset test (asynchronous)
    reset_test(true);
    
    -- Wavedrom section
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    reset <= '1';
    x <= '0';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '0';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '0';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '1';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '0';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '1';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '1';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '0';
    
    wait until rising_edge(clk);
    reset <= '0';
    x <= '0';
    
    wait until falling_edge(clk);
    wavedrom_enable <= '0';
    wait for 1 ps;
    
    -- Random test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- {reset,x} <= {($random&31) == 0, ($random&1)==0};
      reset <= '1' when (random_int_0_31 = 0) else '0';
      random_bit(x);
    end loop;
    
    -- Signal completion
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;