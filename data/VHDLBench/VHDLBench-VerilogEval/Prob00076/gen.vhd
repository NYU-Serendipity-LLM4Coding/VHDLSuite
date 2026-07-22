-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 6-to-1 Multiplexer Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    sel            : out std_logic_vector(2 downto 0);
    data0          : out std_logic_vector(3 downto 0);
    data1          : out std_logic_vector(3 downto 0);
    data2          : out std_logic_vector(3 downto 0);
    data3          : out std_logic_vector(3 downto 0);
    data4          : out std_logic_vector(3 downto 0);
    data5          : out std_logic_vector(3 downto 0);
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
    variable sel_int  : integer;
    
    -- Random 4-bit vector generator
    procedure random_4bit(signal sig : out std_logic_vector(3 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
    -- Random 3-bit vector generator
    procedure random_3bit(signal sig : out std_logic_vector(2 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
  begin
    -- Initialize (matches Verilog initial block)
    data0 <= x"A";  -- 4'ha
    data1 <= x"B";  -- 4'hb
    data2 <= x"C";  -- 4'hc
    data3 <= x"D";  -- 4'hd
    data4 <= x"E";  -- 4'he
    data5 <= x"F";  -- 4'hf
    sel <= "111";   -- 3'b111
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start(...)
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(8) @(posedge clk) sel <= sel + 1;
    for i in 0 to 7 loop
      wait until rising_edge(clk);
      sel_int := to_integer(unsigned(sel));
      sel_int := sel_int + 1;
      sel <= std_logic_vector(to_unsigned(sel_int mod 8, 3));
    end loop;
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Matches Verilog: {data0, data1, data2, data3} <= $urandom;
      random_4bit(data0);
      random_4bit(data1);
      random_4bit(data2);
      random_4bit(data3);
      
      -- Matches Verilog: {data4, data5, sel} <= $urandom;
      random_4bit(data4);
      random_4bit(data5);
      random_3bit(sel);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;