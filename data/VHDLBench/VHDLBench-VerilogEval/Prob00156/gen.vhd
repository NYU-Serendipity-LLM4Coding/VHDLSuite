-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Timer FSM Test
-- Provides test sequences for pattern detection and timing verification
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk          : in  std_logic;
    reset        : out std_logic;
    data         : out std_logic;
    ack          : out std_logic;
    tb_match     : in  boolean;
    counting_dut : in  std_logic;
    sim_done     : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable failed   : std_logic := '0';
    variable counting_cycles : integer := 0;
    
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    procedure random_reset(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8192.0));
      sig <= '1' when rand_int = 0 else '0';
    end procedure;
    
    procedure random_ack(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '1' when rand_int /= 0 else '0';
    end procedure;
    
  begin
    sim_done <= false;
    reset <= '0';
    data <= '0';
    ack <= 'X';
    failed := '0';
    counting_cycles := 0;
    
    -- First test sequence
    wait until rising_edge(clk);
    failed := '0';
    reset <= '1';
    data <= '0';
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
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '0';
    
    wait until rising_edge(clk);
    data <= '1';
    
    wait until rising_edge(clk);
    data <= 'X';
    
    -- Count cycles while counting is active, wait 2000 cycles total
    for i in 1 to 2000 loop
      wait until rising_edge(clk);
      if counting_dut = '1' then
        counting_cycles := counting_cycles + 1;
      end if;
      if not tb_match then
        failed := '1';
      end if;
    end loop;
    
    ack <= '0';
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
      if not tb_match then
        failed := '1';
      end if;
    end loop;
    
    ack <= '1';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    ack <= '0';
    data <= '1';
    
    -- Check first counting period
    if counting_cycles /= 2000 then
      report "Hint: The first test case should count for 2000 cycles. Your circuit counted " & 
             integer'image(counting_cycles) severity note;
    end if;
    counting_cycles := 0;
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    ack <= 'X';
    data <= '1';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    data <= '0';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    data <= '1';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    data <= '1';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    data <= '1';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    data <= '1';
    
    wait until rising_edge(clk);
    if not tb_match then
      failed := '1';
    end if;
    data <= '0';
    
    -- Wait 14800 cycles and count
    for i in 1 to 14800 loop
      wait until rising_edge(clk);
      if counting_dut = '1' then
        counting_cycles := counting_cycles + 1;
      end if;
      if not tb_match then
        failed := '1';
      end if;
    end loop;
    
    ack <= '0';
    
    for i in 1 to 400 loop
      wait until rising_edge(clk);
      if counting_dut = '1' then
        counting_cycles := counting_cycles + 1;
      end if;
      if not tb_match then
        failed := '1';
      end if;
    end loop;
    
    -- Check second counting period
    if counting_cycles /= 15000 then
      report "Hint: The second test case should count for 15000 cycles. Your circuit counted " & 
             integer'image(counting_cycles) severity note;
    end if;
    
    if failed = '1' then
      report "Hint: Your FSM didn't pass the sample timing diagram posted with the problem statement. Perhaps try debugging that?" severity note;
    end if;
    
    -- Random testing: repeat(1000) @(posedge clk, negedge clk)
    for i in 1 to 1000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_reset(reset);
      random_bit(data);
      random_ack(ack);
    end loop;
    
    -- repeat(100000) @(posedge clk)
    for i in 1 to 100000 loop
      wait until rising_edge(clk);
      random_reset(reset);
      random_bit(data);
      random_ack(ack);
    end loop;
    
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;