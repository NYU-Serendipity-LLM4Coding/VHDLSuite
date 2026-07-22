-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Two-Bit Saturating Counter Test
-- Tests asynchronous reset, count up/down, and random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk                      : in  std_logic;
    areset                   : out std_logic;
    train_valid              : out std_logic;
    train_taken              : out std_logic;
    tb_match                 : in  boolean;
    wavedrom_title           : out string(1 to 512);
    wavedrom_enable          : out std_logic;
    wavedrom_hide_after_time : out integer;
    sim_done                 : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset_internal      : std_logic := '0';
  signal train_taken_r       : std_logic := '0';
  signal train_valid_internal: std_logic := '0';
begin

  -- Matches Verilog: assign areset = reset;
  areset <= reset_internal;
  
  -- Matches Verilog: assign train_taken = train_valid ? train_taken_r : 1'bx;
  -- In VHDL, we'll just use train_taken_r when train_valid is active
  train_taken <= train_taken_r when train_valid_internal = '1' else 'X';
  train_valid <= train_valid_internal;

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable arfail   : boolean;
    variable srfail   : boolean;
    variable datafail : boolean;
    
    -- Helper procedure for random 2-bit value
    procedure random_2bits(signal val1, val2 : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      val1 <= '1' when (rand_int >= 2) else '0';
      val2 <= '1' when ((rand_int mod 2) = 1) else '0';
    end procedure;
    
    -- Reset test procedure (matches Verilog task reset_test)
    procedure reset_test(async : boolean := false) is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset_internal <= '0';
      
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset_internal <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset_internal <= '0';
      
      -- Note: In VHDL we can't easily print hints like Verilog $display
      -- These would be handled by the testbench report process
    end procedure;
    
  begin
    -- Initialize
    reset_internal <= '0';
    train_taken_r <= '0';
    train_valid_internal <= '0';
    wavedrom_enable <= '0';
    wavedrom_hide_after_time <= 0;
    sim_done <= false;
    
    -- Initial sequence
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset_internal <= '1';
    wait until rising_edge(clk);
    reset_internal <= '0';
    train_taken_r <= '1';
    train_valid_internal <= '1';
    
    -- Wavedrom: "Asynchronous reset"
    wavedrom_enable <= '1';
    reset_test(true);  -- Test for asynchronous reset
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    reset_internal <= '1';
    train_taken_r <= '1';
    train_valid_internal <= '0';
    wait until rising_edge(clk);
    reset_internal <= '0';
    
    -- Wavedrom: "Count up, then down"
    wavedrom_enable <= '1';
    train_taken_r <= '1';
    
    -- Count up sequence
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '0';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '0';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    
    -- Count down sequence
    train_taken_r <= '0';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '0';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    wait until rising_edge(clk);
    train_valid_internal <= '0';
    wait until rising_edge(clk);
    train_valid_internal <= '1';
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random testing: repeat(1000) @(posedge clk, negedge clk)
    for i in 1 to 1000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_2bits(train_valid_internal, train_taken_r);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;