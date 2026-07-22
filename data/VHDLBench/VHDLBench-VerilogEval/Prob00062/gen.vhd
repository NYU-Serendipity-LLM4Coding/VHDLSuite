-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 8-bit 2-to-1 Mux Test
-- Provides predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    sel            : out std_logic;
    a              : out std_logic_vector(7 downto 0);
    b              : out std_logic_vector(7 downto 0);
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
    
    -- Random 17-bit vector generator (8 bits a + 8 bits b + 1 bit sel)
    procedure random_vector(
      signal sig_a   : out std_logic_vector(7 downto 0);
      signal sig_b   : out std_logic_vector(7 downto 0);
      signal sig_sel : out std_logic) is
      variable rand_17bit : integer;
    begin
      uniform(seed1, seed2, rand_val);
      rand_17bit := integer(floor(rand_val * real(2**17)));
      sig_a   <= std_logic_vector(to_unsigned((rand_17bit / 512) mod 256, 8));
      sig_b   <= std_logic_vector(to_unsigned((rand_17bit / 2) mod 256, 8));
      sig_sel <= '1' when (rand_17bit mod 2) = 1 else '0';
    end procedure;
    
  begin
    -- Initialize
    a <= (others => '0');
    b <= (others => '0');
    sel <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors
    -- {a, b, sel} format
    
    wait until rising_edge(clk);
    a <= x"aa";
    b <= x"bb";
    sel <= '0';
    
    wait until falling_edge(clk);
    a <= x"aa";
    b <= x"bb";
    sel <= '0';
    
    wait until rising_edge(clk);
    a <= x"aa";
    b <= x"bb";
    sel <= '1';
    
    wait until falling_edge(clk);
    a <= x"aa";
    b <= x"bb";
    sel <= '0';
    
    wait until rising_edge(clk);
    a <= x"aa";
    b <= x"bb";
    sel <= '1';
    
    wait until falling_edge(clk);
    a <= x"aa";
    b <= x"bb";
    sel <= '1';
    
    -- Second set with different a, b values
    wait until rising_edge(clk);
    a <= x"ff";
    b <= x"00";
    sel <= '0';
    
    wait until falling_edge(clk);
    sel <= '0';
    
    wait until rising_edge(clk);
    sel <= '1';
    
    wait until falling_edge(clk);
    sel <= '0';
    
    wait until rising_edge(clk);
    sel <= '1';
    
    wait until falling_edge(clk);
    sel <= '1';
    
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
      random_vector(a, b, sel);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;