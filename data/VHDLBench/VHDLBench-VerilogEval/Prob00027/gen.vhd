-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Full Adder Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic;
    b              : out std_logic;
    cin            : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 3-bit concatenation
  signal inputs : std_logic_vector(2 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, cin}
  a   <= inputs(2);
  b   <= inputs(1);
  cin <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 3-bit test vector
    procedure apply_vector(vec : std_logic_vector(2 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 3-bit vector generator (replaces Verilog $random)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start();
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- Matches Verilog sequence: @(posedge clk) {a,b,cin} <= 3'b...
    
    wait until rising_edge(clk);
    apply_vector("000");  -- 3'b000
    
    wait until rising_edge(clk);
    apply_vector("010");  -- 3'b010
    
    wait until rising_edge(clk);
    apply_vector("100");  -- 3'b100
    
    wait until rising_edge(clk);
    apply_vector("110");  -- 3'b110
    
    wait until rising_edge(clk);
    apply_vector("000");  -- 3'b000
    
    wait until rising_edge(clk);
    apply_vector("001");  -- 3'b001
    
    wait until rising_edge(clk);
    apply_vector("011");  -- 3'b011
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
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