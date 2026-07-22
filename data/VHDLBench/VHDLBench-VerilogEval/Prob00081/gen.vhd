-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 7458 Chip Test
-- Generates systematic test patterns followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    p1a            : out std_logic;
    p1b            : out std_logic;
    p1c            : out std_logic;
    p1d            : out std_logic;
    p1e            : out std_logic;
    p1f            : out std_logic;
    p2a            : out std_logic;
    p2b            : out std_logic;
    p2c            : out std_logic;
    p2d            : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal p1_signals : std_logic_vector(5 downto 0);
  signal p2_signals : std_logic_vector(3 downto 0);
begin

  -- Split concatenated signals to individual outputs
  p1a <= p1_signals(5);
  p1b <= p1_signals(4);
  p1c <= p1_signals(3);
  p1d <= p1_signals(2);
  p1e <= p1_signals(1);
  p1f <= p1_signals(0);
  
  p2a <= p2_signals(3);
  p2b <= p2_signals(2);
  p2c <= p2_signals(1);
  p2d <= p2_signals(0);

  stimulus_process : process
    variable count    : integer := 0;
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Generate random 8-bit vector
    procedure random_vector(signal sig : out std_logic_vector) is
      variable temp : unsigned(sig'length - 1 downto 0);
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * real(2**sig'length)));
      temp := to_unsigned(rand_int, sig'length);
      sig <= std_logic_vector(temp);
    end procedure;
    
  begin
    -- Initialize
    count := 0;
    p1_signals <= (others => '0');
    p2_signals <= (others => '0');
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(20) @(posedge clk)
    -- Verilog: {p1a,p1b,p1c,p1d,p1e,p1f} <= {count[2:0], count[3:1]};
    -- Verilog: {p2a,p2b,p2c,p2d} <= count;
    for i in 0 to 19 loop
      wait until rising_edge(clk);
      
      -- count[2:0] = bits 2,1,0 (3 bits)
      -- count[3:1] = bits 3,2,1 (3 bits)
      -- {count[2:0], count[3:1]} = 6-bit concatenation
      p1_signals(5 downto 3) <= std_logic_vector(to_unsigned(count, 4)(2 downto 0));
      p1_signals(2 downto 0) <= std_logic_vector(to_unsigned(count, 4)(3 downto 1));
      
      -- p2 gets count[3:0]
      p2_signals <= std_logic_vector(to_unsigned(count, 4));
      
      count := count + 1;
    end loop;
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(400) @(posedge clk, negedge clk)
    -- Verilog: {p1a,p1b,p1c,p1d,p2a,p2b,p2c,p2d} <= $random;
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate 8-bit random: {p1a,p1b,p1c,p1d,p2a,p2b,p2c,p2d}
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      
      -- Split into p1 and p2 signals
      p1_signals(3 downto 0) <= std_logic_vector(to_unsigned(rand_int, 8)(7 downto 4));
      p2_signals <= std_logic_vector(to_unsigned(rand_int, 8)(3 downto 0));
      
      -- p1e and p1f get random values too
      uniform(seed1, seed2, rand_val);
      p1_signals(5) <= '1' when rand_val > 0.5 else '0';
      uniform(seed1, seed2, rand_val);
      p1_signals(4) <= '1' when rand_val > 0.5 else '0';
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;