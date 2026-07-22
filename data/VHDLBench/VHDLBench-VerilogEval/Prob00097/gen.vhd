-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 9-to-1 Multiplexer Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic_vector(15 downto 0);
    b              : out std_logic_vector(15 downto 0);
    c              : out std_logic_vector(15 downto 0);
    d              : out std_logic_vector(15 downto 0);
    e              : out std_logic_vector(15 downto 0);
    f              : out std_logic_vector(15 downto 0);
    g              : out std_logic_vector(15 downto 0);
    h              : out std_logic_vector(15 downto 0);
    i              : out std_logic_vector(15 downto 0);
    sel            : out std_logic_vector(3 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 123456;
    variable seed2    : positive := 789012;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 16-bit vector generator
    procedure random_vector16(signal vec : out std_logic_vector(15 downto 0)) is
      variable temp : unsigned(15 downto 0);
    begin
      for j in 0 to 15 loop
        uniform(seed1, seed2, rand_val);
        temp(j) := '1' when rand_val > 0.5 else '0';
      end loop;
      vec <= std_logic_vector(temp);
    end procedure;
    
    -- Random 4-bit selector
    procedure random_sel(signal s : out std_logic_vector(3 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      s <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: {a,b,c,d,e,f,g,h,i,sel} <= { 16'ha, 16'hb, ... }
    a   <= x"000a";
    b   <= x"000b";
    c   <= x"000c";
    d   <= x"000d";
    e   <= x"000e";
    f   <= x"000f";
    g   <= x"0011";
    h   <= x"0012";
    i   <= x"0013";
    sel <= x"0";
    
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start();
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test sequence
    wait until rising_edge(clk);
    sel <= x"1";
    
    wait until rising_edge(clk);
    sel <= x"2";
    
    wait until rising_edge(clk);
    sel <= x"3";
    
    wait until rising_edge(clk);
    sel <= x"4";
    
    wait until rising_edge(clk);
    sel <= x"7";
    
    wait until rising_edge(clk);
    sel <= x"8";
    
    wait until rising_edge(clk);
    sel <= x"9";
    
    wait until rising_edge(clk);
    sel <= x"a";
    
    wait until rising_edge(clk);
    sel <= x"b";
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(negedge clk, posedge clk)
    for idx in 1 to 200 loop
      if (idx mod 2) = 1 then
        wait until falling_edge(clk);
      else
        wait until rising_edge(clk);
      end if;
      
      -- Matches Verilog: {a,b,c,d,e,f,g,h,i,sel} <= {$random, $random, ...}
      random_vector16(a);
      random_vector16(b);
      random_vector16(c);
      random_vector16(d);
      random_vector16(e);
      random_vector16(f);
      random_vector16(g);
      random_vector16(h);
      random_vector16(i);
      random_sel(sel);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;