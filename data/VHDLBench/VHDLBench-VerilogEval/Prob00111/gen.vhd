-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Moore State Machine Test
-- Generates reset test followed by predetermined and random test vectors
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    j               : out std_logic;
    k               : out std_logic;
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
    
    -- Random 2-bit generator
    procedure random_2bits(signal sig_k, sig_j : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      sig_k <= '1' when (rand_int >= 2) else '0';
      sig_j <= '1' when ((rand_int mod 2) = 1) else '0';
    end procedure;
    
    -- Reset test task
    procedure reset_test is
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
      
      -- Note: Warning messages are handled in testbench for consistency
    end procedure;
    
    -- Predetermined test data array (matches Verilog: reg [0:11][1:0] d)
    -- d = 24'b000101010010101111111111
    -- Split into 12 2-bit values: {k, j}
    type test_data_t is array (0 to 11) of std_logic_vector(1 downto 0);
    constant test_data : test_data_t := (
      "00", "01", "01", "00", "10", "10", "11", "11", "11", "11", "11", "11"
    );
    
  begin
    -- Initialize
    reset <= '1';
    j <= '0';
    k <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog initial block sequence
    wait until rising_edge(clk);
    reset <= '0';
    j <= '1';
    
    wait until rising_edge(clk);
    j <= '0';
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Reset test
    reset_test;
    
    -- Apply predetermined test vectors
    -- Matches Verilog: for (int i=0;i<12;i++) @(posedge clk) {k, j} <= d[i];
    for i in 0 to 11 loop
      wait until rising_edge(clk);
      k <= test_data(i)(1);  -- MSB is k
      j <= test_data(i)(0);  -- LSB is j
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    -- Matches Verilog: {j,k} <= $random; reset <= !($random & 7);
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      random_2bits(k, j);
      
      -- Generate reset with probability ~1/8
      -- Matches: reset <= !($random & 7) which is 0 when bottom 3 bits != 0
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      reset <= '0' when (rand_int /= 0) else '1';
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;