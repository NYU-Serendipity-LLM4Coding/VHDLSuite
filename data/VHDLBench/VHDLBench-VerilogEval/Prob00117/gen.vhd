-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Sequential Counter Circuit
-- Generates test pattern for counter with conditional reset/load
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic;
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
    variable rand_5bit : unsigned(4 downto 0);
    
    -- Random bit generator with reduction AND
    -- Matches Verilog: &((5)'($urandom))
    procedure random_bit_reduced_and(signal sig : out std_logic) is
      variable temp : unsigned(4 downto 0);
    begin
      uniform(seed1, seed2, rand_val);
      temp := to_unsigned(integer(floor(rand_val * 32.0)), 5);
      -- Reduction AND: all bits must be '1'
      if temp = "11111" then
        sig <= '1';
      else
        sig <= '0';
      end if;
    end procedure;
    
  begin
    -- Initialize
    a <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) {a} <= 1;
    wait until falling_edge(clk);
    a <= '1';
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Unknown circuit");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- @(posedge clk) {a} <= 0;
    wait until rising_edge(clk);
    a <= '0';
    
    -- repeat(11) @(posedge clk);
    for i in 1 to 11 loop
      wait until rising_edge(clk);
    end loop;
    
    -- @(negedge clk) a <= 1;
    wait until falling_edge(clk);
    a <= '1';
    
    -- repeat(5) @(posedge clk, negedge clk);
    for i in 1 to 5 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
    end loop;
    
    -- a <= 0;
    a <= '0';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    -- wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit_reduced_and(a);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;