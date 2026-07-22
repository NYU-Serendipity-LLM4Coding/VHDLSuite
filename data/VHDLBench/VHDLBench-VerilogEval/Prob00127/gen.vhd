-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Lemmings FSM Test
-- Tests asynchronous reset and random state transitions
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    areset          : out std_logic;
    bump_left       : out std_logic;
    bump_right      : out std_logic;
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
    
    -- Random 2-bit vector generator
    procedure random_2bits(signal sig1, sig2 : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      sig1 <= '1' when (rand_int mod 2) = 1 else '0';
      sig2 <= '1' when (rand_int / 2) = 1 else '0';
    end procedure;
    
    -- Reset test procedure (simplified from Verilog task)
    procedure reset_test(async : boolean := false) is
      variable arfail, srfail, datafail : boolean;
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      -- Wait 3 clock cycles
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
    reset <= '1';
    bump_right <= '1';
    bump_left <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Wavedrom section: "Asynchronous reset"
    wavedrom_enable <= '1';
    
    -- Test asynchronous reset
    reset_test(true);
    
    -- Wait 3 clocks
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- {bump_right, bump_left} <= 2
    bump_right <= '1';
    bump_left <= '0';
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- {bump_right, bump_left} <= 1
    bump_right <= '0';
    bump_left <= '1';
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- {bump_right, bump_left} <= $random & $random;
      random_2bits(bump_left, bump_right);
      
      -- reset <= !($random & 31);
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      reset <= '0' when (rand_int = 0) else '1';
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;