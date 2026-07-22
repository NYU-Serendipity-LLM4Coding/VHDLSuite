-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Decade Counter Test
-- Tests synchronous reset, enable control, and counting behavior
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    slowena         : out std_logic;
    reset           : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    -- Local random seeds (not shared)
    variable seed1 : positive := 12345;
    variable seed2 : positive := 67890;
    variable hint1 : boolean;
    
    -- Random bit generator procedure
    procedure random_bit(signal sig : out std_logic) is
      variable rand_val : real;
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random with probability (for $random & mask patterns)
    function random_prob(prob_ones : real) return std_logic is
      variable rv : real;
    begin
      uniform(seed1, seed2, rv);
      if rv < prob_ones then
        return '1';
      else
        return '0';
      end if;
    end function;
    
    -- Reset test procedure (simplified - matches Verilog behavior)
    procedure reset_test(
      signal clk_sig   : in std_logic;
      signal reset_sig : out std_logic;
      tb_match_val     : in boolean
    ) is
      variable arfail, srfail, datafail : boolean;
    begin
      wait until rising_edge(clk_sig);
      wait until rising_edge(clk_sig);
      reset_sig <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk_sig);
      end loop;
      
      wait until falling_edge(clk_sig);
      datafail := not tb_match_val;
      reset_sig <= '1';
      
      wait until rising_edge(clk_sig);
      arfail := not tb_match_val;
      
      wait until rising_edge(clk_sig);
      srfail := not tb_match_val;
      reset_sig <= '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    slowena <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Wavedrom: "Synchronous reset and counting."
    wavedrom_enable <= '1';
    reset_test(clk, reset, tb_match);
    
    for i in 1 to 12 loop
      wait until rising_edge(clk);
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    
    -- Test enable/disable at counter = 9
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '0';
    
    for i in 1 to 9 loop
      wait until rising_edge(clk);
    end loop;
    
    slowena <= '0';
    wait until falling_edge(clk);
    hint1 := tb_match;
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Check hint condition (counter at 9, not enabled)
    -- if (hint1 && !tb_match) - hint would be displayed
    
    slowena <= '1';
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '0';
    
    -- Wavedrom: "Enable/disable"
    wavedrom_enable <= '1';
    for i in 1 to 15 loop
      wait until rising_edge(clk);
      slowena <= random_prob(0.5);  -- Matches !($random & 1)
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    
    -- Random test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      slowena <= random_prob(0.25);    -- Matches !($random & 3)
      reset <= random_prob(0.03125);   -- Matches !($random & 31)
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;