-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 8-bit D Flip-Flop Test
-- Generates random 8-bit input data on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    d              : out std_logic_vector(7 downto 0);
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
    
    -- Random 8-bit vector generator (replaces Verilog $random % 256)
    procedure random_byte(signal sig : out std_logic_vector(7 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
    -- Wavedrom tasks (simplified)
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
    d <= x"00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(posedge clk);
    wait until rising_edge(clk);
    
    -- Start wavedrom
    wavedrom_start("Positive-edge triggered DFF");
    
    -- Matches Verilog: repeat(10) @(posedge clk);
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    -- Matches Verilog: #100;
    wait for 100 ps;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;
  
  -- Matches Verilog: always @(posedge clk, negedge clk) d <= $random % 256;
  -- This runs continuously on both clock edges
  random_process : process(clk)
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
  begin
    if rising_edge(clk) or falling_edge(clk) then
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      d <= std_logic_vector(to_unsigned(rand_int, 8));
    end if;
  end process;

end architecture behavioral;