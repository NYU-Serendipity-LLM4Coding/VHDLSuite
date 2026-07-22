-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Down-Counter Timer Test
-- Generates load and data signals with predetermined and random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk                : in  std_logic;
    load               : out std_logic;
    data               : out std_logic_vector(9 downto 0);
    tb_match           : in  boolean;
    wavedrom_title     : out string(1 to 512);
    wavedrom_enable    : out std_logic;
    wavedrom_hide_after_time : out integer;
    sim_done           : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random range generator (replaces Verilog $urandom_range)
    procedure random_range(min_val, max_val : integer; signal sig : out std_logic_vector) is
      variable range_val : integer;
      variable local_rand : real;
    begin
      uniform(seed1, seed2, local_rand);
      range_val := min_val + integer(floor(local_rand * real(max_val - min_val + 1)));
      if range_val > max_val then
        range_val := max_val;
      end if;
      sig <= std_logic_vector(to_unsigned(range_val, sig'length));
    end procedure;
    
    -- Random bit with probability (replaces !($urandom & 10'hf))
    -- Returns '1' if random value AND 0xF equals 0
    procedure random_bit_prob(signal sig : out std_logic) is
      variable local_rand : real;
      variable local_int : integer;
    begin
      uniform(seed1, seed2, local_rand);
      local_int := integer(floor(local_rand * 16.0));  -- 0 to 15
      -- Bitwise AND with 0xF (15): if result is 0, return '1', else '0'
      -- This mimics !($urandom & 10'hf)
      if (local_int mod 16) = 0 then
        sig <= '1';
      else
        sig <= '0';
      end if;
    end procedure;
    
    -- Wavedrom procedures (simplified)
    procedure wavedrom_start(title : string) is
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
    load <= '0';
    data <= (others => '0');
    wavedrom_enable <= '0';
    wavedrom_hide_after_time <= 0;
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Wavedrom section: "Count 3, then 10 cycles"
    wavedrom_start("Count 3, then 10 cycles");
    
    -- @(posedge clk) {data, load} <= {10'd3, 1'b1};
    wait until rising_edge(clk);
    data <= std_logic_vector(to_unsigned(3, 10));
    load <= '1';
    
    -- @(posedge clk) {data, load} <= {10'hx, 1'b0};
    wait until rising_edge(clk);
    data <= (others => 'X');
    load <= '0';
    
    -- @(posedge clk) load <= 0; (3 times)
    wait until rising_edge(clk);
    load <= '0';
    
    wait until rising_edge(clk);
    load <= '0';
    
    wait until rising_edge(clk);
    load <= '0';
    
    -- @(posedge clk) {data, load} <= {10'd10, 1'b1};
    wait until rising_edge(clk);
    data <= std_logic_vector(to_unsigned(10, 10));
    load <= '1';
    
    -- @(posedge clk) {data, load} <= {10'hx, 1'b0};
    wait until rising_edge(clk);
    data <= (others => 'X');
    load <= '0';
    
    -- repeat(12) @(posedge clk);
    for i in 1 to 12 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    -- Test sequence: Load 16, then 0, then 1023
    -- @(posedge clk) {load, data} <= {1'b1, 10'h10};
    wait until rising_edge(clk);
    load <= '1';
    data <= std_logic_vector(to_unsigned(16#10#, 10));
    
    -- @(posedge clk) {load, data} <= {1'b0, 10'h10};
    wait until rising_edge(clk);
    load <= '0';
    data <= std_logic_vector(to_unsigned(16#10#, 10));
    
    -- @(posedge clk) {load, data} <= {1'b1, 10'h0}; -- Load 0
    wait until rising_edge(clk);
    load <= '1';
    data <= std_logic_vector(to_unsigned(0, 10));
    
    -- @(posedge clk) {load, data} <= {1'b1, 10'h3ff}; -- Load 1023
    wait until rising_edge(clk);
    load <= '1';
    data <= std_logic_vector(to_unsigned(16#3FF#, 10));
    
    -- @(posedge clk) {load, data} <= {1'b0, 10'h0};
    wait until rising_edge(clk);
    load <= '0';
    data <= std_logic_vector(to_unsigned(0, 10));
    
    -- repeat(1040) @(posedge clk);
    for i in 1 to 1040 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Random testing: repeat(2500) @(posedge clk)
    for i in 1 to 2500 loop
      wait until rising_edge(clk);
      -- load <= !($urandom & 10'hf);
      random_bit_prob(load);
      -- data <= $urandom_range(0,32);
      random_range(0, 32, data);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;