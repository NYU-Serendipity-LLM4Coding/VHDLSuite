-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 8-bit D Flip-Flop with Async Reset
-- Generates test vectors including reset testing and random data
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    d               : out std_logic_vector(7 downto 0);
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

  -- Matches Verilog: assign areset = reset;
  areset <= reset;

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random byte generator
    procedure random_byte(signal sig : out std_logic_vector(7 downto 0)) is
      variable r : real;
      variable ri : integer;
    begin
      uniform(seed1, seed2, r);
      ri := integer(floor(r * 256.0));
      sig <= std_logic_vector(to_unsigned(ri, 8));
    end procedure;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      if r > 0.5 then
        sig <= '1';
      else
        sig <= '0';
      end if;
    end procedure;
    
    -- Reset test task (matches Verilog reset_test)
    procedure reset_test(async : boolean := false) is
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
      
      -- Hint messages (simplified, no $display in VHDL stimulus)
      -- These would be reported in testbench if needed
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    random_byte(d);
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk); @(negedge clk);
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Reset test with async=1
    reset_test(async => true);
    
    -- repeat(7) @(negedge clk) d <= $random;
    for i in 1 to 7 loop
      wait until falling_edge(clk);
      random_byte(d);
    end loop;
    
    -- @(posedge clk) reset <= 1;
    wait until rising_edge(clk);
    reset <= '1';
    
    -- @(negedge clk) reset <= 0; d <= $random;
    wait until falling_edge(clk);
    reset <= '0';
    random_byte(d);
    
    -- repeat(2) @(negedge clk) d <= $random;
    for i in 1 to 2 loop
      wait until falling_edge(clk);
      random_byte(d);
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Main random test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- reset <= !($random & 15);
      -- This means: generate random, AND with 15, then invert
      -- Effectively: reset is '0' most of the time (15/16), '1' occasionally
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      if rand_int /= 0 then
        reset <= '0';
      else
        reset <= '1';
      end if;
      
      random_byte(d);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;