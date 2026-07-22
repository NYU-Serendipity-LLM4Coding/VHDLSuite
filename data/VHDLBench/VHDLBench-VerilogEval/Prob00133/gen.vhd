-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for FSM Test
-- Generates reset, s, and w signals for state machine testing
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    reset    : out std_logic;
    s        : out std_logic;
    w        : out std_logic;
    tb_match : in  boolean;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1       : positive := 12345;
    variable seed2       : positive := 67890;
    variable rand_val    : real;
    variable spulse_fail : boolean := false;
    variable failed      : boolean := false;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random with masking (replaces Verilog: !($random & mask))
    -- Returns '1' if (random_value AND mask) == 0
    procedure random_masked(signal sig : out std_logic; mask : integer) is
      variable rand_int : integer;
      variable local_rand : real;
    begin
      uniform(seed1, seed2, local_rand);
      rand_int := integer(floor(local_rand * 128.0));
      -- Bitwise AND operation
      if ((rand_int mod (mask + 1)) = 0) then
        sig <= '1';
      else
        sig <= '0';
      end if;
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    s <= '0';
    w <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial reset sequence
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Set s to start FSM
    s <= '1';
    
    -- First test sequence: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(w);
      
      -- Track failures during first sequence
      if not tb_match then
        failed := true;
      end if;
    end loop;
    
    -- Reset pulse
    wait until rising_edge(clk);
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Second test sequence: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(w);
      
      if not tb_match then
        failed := true;
      end if;
    end loop;
    
    -- Check spulse_fail
    wait until rising_edge(clk);
    spulse_fail := failed;
    
    -- Final random test: repeat(500) @(negedge clk)
    for i in 1 to 500 loop
      wait until falling_edge(clk);
      random_masked(reset, 63);  -- !($random & 63)
      random_masked(s, 7);       -- !($random & 7)
      random_bit(w);
      
      if not tb_match then
        failed := true;
      end if;
    end loop;
    
    -- Display hint if needed (informational only in VHDL)
    -- Matches Verilog: if (failed && !spulse_fail)
    -- Note: This is just a comment in VHDL, actual display done in testbench
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;