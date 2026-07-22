-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 100-bit 2-to-1 Multiplexer Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(99 downto 0);
    b              : out std_logic_vector(99 downto 0);
    sel            : out std_logic;
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
    
    -- Random 32-bit generator (replaces Verilog $random)
    impure function random_32bit return std_logic_vector is
      variable result : std_logic_vector(31 downto 0);
      variable temp   : integer;
    begin
      uniform(seed1, seed2, rand_val);
      temp := integer(floor(rand_val * real(2**31)));
      result := std_logic_vector(to_signed(temp, 32));
      return result;
    end function;
    
    -- Random 100-bit vector generator (using multiple 32-bit calls)
    impure function random_100bit return std_logic_vector is
      variable result : std_logic_vector(99 downto 0);
    begin
      result(31 downto 0)   := random_32bit;
      result(63 downto 32)  := random_32bit;
      result(95 downto 64)  := random_32bit;
      result(99 downto 96)  := random_32bit(3 downto 0);
      return result;
    end function;
    
    -- Random bit generator
    impure function random_bit return std_logic is
      variable result : std_logic;
    begin
      uniform(seed1, seed2, rand_val);
      if rand_val > 0.5 then
        result := '1';
      else
        result := '0';
      end if;
      return result;
    end function;
    
  begin
    -- Initialize
    -- Matches Verilog: a <= 'hdeadbeef; b <= 'h5eaf00d; sel <= 0;
    -- Note: Verilog 'h literals auto-extend to port width
    -- Use resize() with qualified expressions for literals
    a <= std_logic_vector(resize(unsigned'(x"deadbeef"), 100));  -- Extend 32-bit to 100-bit
    b <= std_logic_vector(resize(unsigned'(x"05eaf00d"), 100));  -- Extend 28-bit to 100-bit
    sel <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Wavedrom start
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(6) @(posedge clk) sel <= ~sel;
    for i in 1 to 6 loop
      wait until rising_edge(clk);
      sel <= not sel;
    end loop;
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(100) @(posedge clk, negedge clk)
    -- Matches Verilog: {a,b,sel} <= {$random, $random, $random, $random, $random, $random, $random};
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      a   <= random_100bit;
      b   <= random_100bit;
      sel <= random_bit;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;