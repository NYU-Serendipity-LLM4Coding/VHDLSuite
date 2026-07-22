-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Adder-Subtractor with Zero Flag Test
-- Provides predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    do_sub         : out std_logic;
    a              : out std_logic_vector(7 downto 0);
    b              : out std_logic_vector(7 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    tb_match       : in  boolean;
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
    
    -- Apply 16-bit test vector and split to a, b
    procedure apply_ab(vec : std_logic_vector(15 downto 0)) is
    begin
      a <= vec(15 downto 8);
      b <= vec(7 downto 0);
    end procedure;
    
    -- Random 17-bit vector generator (16 bits for a,b + 1 bit for do_sub)
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 131072.0));  -- 2^17
      a <= std_logic_vector(to_unsigned((rand_int / 2) / 256, 8));
      b <= std_logic_vector(to_unsigned((rand_int / 2) mod 256, 8));
      do_sub <= '1' when (rand_int mod 2) = 1 else '0';
    end procedure;
    
  begin
    -- Initialize
    -- Matches Verilog: {a, b} <= 16'haabb;
    apply_ab(x"AABB");
    do_sub <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test sequence
    wait until rising_edge(clk);
    do_sub <= '0';
    
    wait until falling_edge(clk);
    do_sub <= '0';
    
    wait until rising_edge(clk);
    do_sub <= '1';
    
    wait until falling_edge(clk);
    do_sub <= '1';
    
    wait until rising_edge(clk);
    apply_ab(x"0303");
    do_sub <= '0';
    
    wait until falling_edge(clk);
    do_sub <= '0';
    
    wait until rising_edge(clk);
    do_sub <= '1';
    
    wait until falling_edge(clk);
    apply_ab(x"0304");
    do_sub <= '0';
    
    wait until rising_edge(clk);
    do_sub <= '0';
    
    wait until falling_edge(clk);
    do_sub <= '1';
    
    wait until rising_edge(clk);
    apply_ab(x"FD03");
    do_sub <= '0';
    
    wait until falling_edge(clk);
    do_sub <= '0';
    
    wait until rising_edge(clk);
    do_sub <= '1';
    
    wait until falling_edge(clk);
    apply_ab(x"FD04");
    do_sub <= '0';
    
    wait until rising_edge(clk);
    do_sub <= '0';
    
    wait until falling_edge(clk);
    do_sub <= '1';
    
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