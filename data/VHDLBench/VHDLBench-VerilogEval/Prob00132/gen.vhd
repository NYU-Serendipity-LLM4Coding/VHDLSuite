-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Combinational Logic Bug Fix Test
-- Generates test vectors for cpu_overheated, arrived, gas_tank_empty
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    cpu_overheated  : out std_logic;
    arrived         : out std_logic;
    gas_tank_empty  : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 3-bit concatenation
  -- Matches Verilog: logic [2:0] s = 3'b010;
  signal s : std_logic_vector(2 downto 0) := "010";
  
begin

  -- Split concatenated signal to individual outputs
  -- Matches Verilog: assign {cpu_overheated, arrived, gas_tank_empty} = s;
  cpu_overheated <= s(2);
  arrived        <= s(1);
  gas_tank_empty <= s(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 3-bit vector generator (replaces Verilog $urandom)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      s <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize
    s <= "010";  -- Matches Verilog: logic [2:0] s = 3'b010;
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog sequence)
    wait until rising_edge(clk);
    s <= "010";  -- 3'b010
    
    wait until rising_edge(clk);
    s <= "100";  -- 3'b100
    
    wait until rising_edge(clk);
    s <= "100";  -- 3'b100
    
    wait until rising_edge(clk);
    s <= "001";  -- 3'b001
    
    wait until rising_edge(clk);
    s <= "000";  -- 3'b000
    
    wait until rising_edge(clk);
    s <= "100";  -- 3'b100
    
    wait until rising_edge(clk);
    s <= "110";  -- 3'b110
    
    wait until rising_edge(clk);
    s <= "111";  -- 3'b111
    
    wait until rising_edge(clk);
    s <= "111";  -- 3'b111
    
    wait until rising_edge(clk);
    s <= "111";  -- 3'b111
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;