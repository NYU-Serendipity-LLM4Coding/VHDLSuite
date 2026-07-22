-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Moore State Machine Test
-- Generates test vectors including reset testing
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
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable arfail   : boolean;
    variable srfail   : boolean;
    variable datafail : boolean;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random with probability (used for reset generation)
    function random_bool_prob return boolean is
      variable rand : real;
      variable rand_int : integer;
    begin
      uniform(seed1, seed2, rand);
      rand_int := integer(floor(rand * 8.0));
      return (rand_int = 0);  -- 1/8 probability
    end function;
    
    -- Reset test task
    procedure reset_test(async : boolean := false) is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      -- Note: Hint messages would be displayed here in Verilog
      -- In VHDL, these would need to be handled in the testbench report
    end procedure;
    
    -- Wavedrom tasks (simplified)
    procedure wavedrom_start(title : string := "") is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
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
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    -- Wavedrom section
    wavedrom_start;
    
    -- Reset test (async=1)
    reset_test(async => true);
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '0';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until rising_edge(clk);
    signal_in <= '1';
    
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
      reset <= '1' when random_bool_prob else '0';
    end loop;
    
    -- Finish
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;