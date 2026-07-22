-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Thermostat Controller Test
-- Generates predetermined test vectors for Winter and Summer modes
-- followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    too_cold       : out std_logic;
    too_hot        : out std_logic;
    mode           : out std_logic;
    fan_on         : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 4-bit concatenation
  -- {too_cold, too_hot, mode, fan_on}
  signal inputs : std_logic_vector(3 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  too_cold <= inputs(3);
  too_hot  <= inputs(2);
  mode     <= inputs(1);
  fan_on   <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 4-bit test vector
    procedure apply_vector(vec : std_logic_vector(3 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 4-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
    -- Wavedrom control (simplified, not functional in VHDL)
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
    inputs <= "0010";  -- 4'b0010
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Winter test section
    wait until falling_edge(clk);
    wavedrom_start("Winter");
    
    wait until rising_edge(clk);
    apply_vector("0010");  -- 4'b0010
    
    wait until rising_edge(clk);
    apply_vector("0010");
    
    wait until rising_edge(clk);
    apply_vector("1010");
    
    wait until rising_edge(clk);
    apply_vector("1011");
    
    wait until rising_edge(clk);
    apply_vector("0010");
    
    wait until rising_edge(clk);
    apply_vector("0011");
    
    wait until rising_edge(clk);
    apply_vector("0010");
    
    wait until rising_edge(clk);
    apply_vector("0110");
    
    wait until rising_edge(clk);
    apply_vector("1110");
    
    wait until rising_edge(clk);
    apply_vector("0111");
    
    wait until rising_edge(clk);
    apply_vector("1111");
    
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- Summer test section
    apply_vector("0000");  -- 4'b0000
    
    wait until falling_edge(clk);
    wavedrom_start("Summer");
    
    wait until rising_edge(clk);
    apply_vector("0000");
    
    wait until rising_edge(clk);
    apply_vector("0000");
    
    wait until rising_edge(clk);
    apply_vector("0100");
    
    wait until rising_edge(clk);
    apply_vector("0101");
    
    wait until rising_edge(clk);
    apply_vector("0000");
    
    wait until rising_edge(clk);
    apply_vector("0001");
    
    wait until rising_edge(clk);
    apply_vector("0000");
    
    wait until rising_edge(clk);
    apply_vector("1000");
    
    wait until rising_edge(clk);
    apply_vector("1100");
    
    wait until rising_edge(clk);
    apply_vector("1001");
    
    wait until rising_edge(clk);
    apply_vector("1101");
    
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;