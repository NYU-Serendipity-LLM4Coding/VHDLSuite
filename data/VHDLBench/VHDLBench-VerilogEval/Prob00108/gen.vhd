-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Rule 90 Cellular Automaton Test
-- Generates load control and data patterns for testing
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    load           : out std_logic;
    data           : out std_logic_vector(511 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable temp_data : std_logic_vector(511 downto 0);
    
    -- Random 512-bit vector generator (simplified - uses lower bits)
    procedure random_vector(signal sig : out std_logic_vector(511 downto 0)) is
      variable temp : std_logic_vector(511 downto 0);
    begin
      for i in 0 to 15 loop  -- Generate 16 chunks of 32 bits
        uniform(seed1, seed2, rand_val);
        rand_int := integer(floor(rand_val * real(2**30)));  -- 30-bit random
        temp(i*32+29 downto i*32) := std_logic_vector(to_unsigned(rand_int, 30));
        temp(i*32+31 downto i*32+30) := "00";
      end loop;
      sig <= temp;
    end procedure;
    
  begin
    -- Initialize
    data <= (others => '0');
    load <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Test 1: Sierpinski triangle pattern
    -- Matches Verilog: data <= 0; data[0] <= 1'b1; load <= 1;
    temp_data := (others => '0');
    temp_data(0) := '1';
    data <= temp_data;
    load <= '1';
    
    wait until rising_edge(clk);
    wavedrom_enable <= '1';  -- wavedrom_start
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Matches Verilog: load <= 0;
    load <= '0';
    
    -- Matches Verilog: repeat(10) @(posedge clk);
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    
    -- wavedrom_stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Test 2: Center bit pattern
    -- Matches Verilog: data <= 0; data[256] <= 1'b1; load <= 1;
    temp_data := (others => '0');
    temp_data(256) := '1';
    data <= temp_data;
    load <= '1';
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    load <= '0';
    
    -- Matches Verilog: repeat(1000) @(posedge clk)
    for i in 1 to 1000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Test 3: Edge bits pattern
    -- Matches Verilog: data <= 512'h1000000000000001;
    temp_data := (others => '0');
    temp_data(0) := '1';
    temp_data(508) := '1';  -- Bit 508 corresponds to hex digit position
    data <= temp_data;
    load <= '1';
    
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 1000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Test 4: Random pattern
    -- Matches Verilog: data <= $random; load <= 1;
    random_vector(data);
    load <= '1';
    
    wait until rising_edge(clk);
    load <= '0';
    
    for i in 1 to 1000 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Test 5: Sequential pattern
    -- Matches Verilog: data <= 0; load <= 1; repeat(20)...
    data <= (others => '0');
    load <= '1';
    
    for i in 1 to 20 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: repeat(2) @(posedge clk) data <= data + 2;
    for i in 1 to 2 loop
      wait until rising_edge(clk);
      data <= std_logic_vector(unsigned(data) + 2);
    end loop;
    
    -- Matches Verilog: @(posedge clk) begin load <= 0; data <= data + 1; end
    wait until rising_edge(clk);
    load <= '0';
    data <= std_logic_vector(unsigned(data) + 1);
    
    -- Matches Verilog: repeat(20) @(posedge clk) data <= data + 1;
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      data <= std_logic_vector(unsigned(data) + 1);
    end loop;
    
    -- Matches Verilog: repeat(500) @(posedge clk)
    for i in 1 to 500 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;