-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for SOP/POS Logic Minimization Test
-- Tests specific input combinations and random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    a               : out std_logic;
    b               : out std_logic;
    c               : out std_logic;
    d               : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal inputs : std_logic_vector(3 downto 0);
  signal fail   : std_logic := '0';
  signal fail1  : std_logic := '0';
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, c, d}
  a <= inputs(3);
  b <= inputs(2);
  c <= inputs(1);
  d <= inputs(0);

  -- Track failures (matches Verilog fail logic)
  fail_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not tb_match then
        fail <= '1';
      end if;
    end if;
  end process;

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
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
    
  begin
    -- Initialize
    inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Test specific combinations (matches Verilog sequence)
    -- @(posedge clk) {a,b,c,d} <= 0;
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(0, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(1, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(2, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(4, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(5, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(6, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(7, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(9, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(10, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(13, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(14, 4)));
    
    wait until rising_edge(clk);
    apply_vector(std_logic_vector(to_unsigned(15, 4)));
    
    -- Capture fail1 after initial tests
    wait until rising_edge(clk);
    fail1 <= fail;
    
    -- Test all 16 combinations
    -- for (int i=0;i<16;i++)
    for i in 0 to 15 loop
      wait until rising_edge(clk);
      apply_vector(std_logic_vector(to_unsigned(i, 4)));
    end loop;
    
    -- Random tests: repeat(50) @(posedge clk, negedge clk)
    for i in 1 to 50 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Display hint if needed (matches Verilog conditional display)
    if fail = '1' and fail1 = '0' then
      report "Hint: Your circuit passes on the 12 required input combinations, but doesn't match the don't-care cases. Are you using minimal SOP and POS?" severity note;
    end if;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;