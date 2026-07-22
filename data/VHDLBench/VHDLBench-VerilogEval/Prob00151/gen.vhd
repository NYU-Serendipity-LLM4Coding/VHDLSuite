-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Timer FSM Test
-- Generates predetermined test sequence followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk           : in  std_logic;
    reset         : out std_logic;
    data          : out std_logic;
    done_counting : out std_logic;
    ack           : out std_logic;
    tb_match      : in  boolean;
    sim_done      : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal failed : std_logic := '0';
begin

  -- Monitor for failures during predetermined sequence
  monitor_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not tb_match then
        failed <= '1';
      end if;
    end if;
  end process;

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator with bias
    procedure random_bit_biased(signal sig : out std_logic; bias : integer) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * real(bias)));
      sig <= '1' when rand_int /= 0 else '0';
    end procedure;
    
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
  begin
    -- Initialize
    reset <= '0';
    data <= '0';
    done_counting <= 'X';
    ack <= 'X';
    sim_done <= false;
    
    -- Initial sequence (matches Verilog testbench)
    wait until rising_edge(clk);
    failed <= '0';
    reset <= '1';
    data <= '0';
    done_counting <= 'X';
    ack <= 'X';
    
    wait until rising_edge(clk);
    data <= '1';
    reset <= '0';
    
    wait until rising_edge(clk);
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '1';
    
    wait until rising_edge(clk);
    data <= '1';
    
    wait until rising_edge(clk);
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '1';
    
    wait until rising_edge(clk);
    data <= 'X';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    done_counting <= '0';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    done_counting <= '1';
    
    wait until rising_edge(clk);
    done_counting <= 'X';
    ack <= '0';
    
    -- repeat(3) @(posedge clk);
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    ack <= '1';
    
    wait until rising_edge(clk);
    ack <= '0';
    data <= '1';
    
    wait until rising_edge(clk);
    ack <= 'X';
    data <= '1';
    
    wait until rising_edge(clk);
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '1';
    
    wait until rising_edge(clk);
    data <= 'X';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    done_counting <= '0';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    done_counting <= '1';
    
    wait until rising_edge(clk);
    
    -- Check if predetermined sequence passed
    if failed = '1' then
      report "Hint: Your FSM didn't pass the sample timing diagram posted with the problem statement. Perhaps try debugging that?";
    end if;
    
    -- Random test sequence
    -- repeat(5000) @(posedge clk, negedge clk)
    for i in 1 to 5000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- reset <= !($random & 255);
      random_bit_biased(reset, 256);
      reset <= not reset;
      
      -- data <= $random;
      random_bit(data);
      
      -- done_counting <= !($random & 31);
      random_bit_biased(done_counting, 32);
      done_counting <= not done_counting;
      
      -- ack <= !($random & 31);
      random_bit_biased(ack, 32);
      ack <= not ack;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;