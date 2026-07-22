-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Byte-Enabled D Flip-Flops
-- Tests synchronous active-low reset and byte-enable functionality
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    d              : out std_logic_vector(15 downto 0);
    byteena        : out std_logic_vector(1 downto 0);
    resetn         : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    tb_match       : in  boolean;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic := '1';
begin

  -- Matches Verilog: assign resetn = ~reset;
  resetn <= not reset;

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 16-bit vector generator
    procedure random_16bit(signal sig : out std_logic_vector(15 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 65536.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 16));
    end procedure;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Reset test task (matches Verilog reset_test)
    procedure reset_test is
      variable arfail, srfail, datafail : boolean;
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      -- Note: Verilog displays hints, but we simplify for VHDL
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    byteena <= "11";
    d <= x"ABCD";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- First test: Synchronous active-low reset
    wait until rising_edge(clk);
    wavedrom_enable <= '1';
    reset_test;
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    
    -- Second test: DFF with byte enables
    byteena <= "11";
    random_16bit(d);
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    for i in 1 to 10 loop
      wait until rising_edge(clk);
      random_16bit(d);
      byteena <= std_logic_vector(unsigned(byteena) + 1);
    end loop;
    
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Matches Verilog: byteena[0] <= ($random & 3) != 0;
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      byteena(0) <= '1' when (rand_int /= 0) else '0';
      
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      byteena(1) <= '1' when (rand_int /= 0) else '0';
      
      random_16bit(d);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;