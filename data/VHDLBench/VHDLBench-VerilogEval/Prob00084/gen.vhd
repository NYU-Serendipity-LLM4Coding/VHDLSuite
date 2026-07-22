-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 8-bit Shift Register with Mux
-- Generates test patterns including wavedrom section and random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    S              : out std_logic;
    enable         : out std_logic;
    A              : out std_logic;
    B              : out std_logic;
    C              : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal ABC : std_logic_vector(2 downto 0);
begin

  -- Split ABC to individual outputs
  A <= ABC(2);
  B <= ABC(1);
  C <= ABC(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random 3-bit value
    procedure random_abc is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      ABC <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
    -- Random 4-bit value (A,B,C,S)
    procedure random_4bit(signal s_sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      ABC <= std_logic_vector(to_unsigned(rand_int / 2, 3));
      s_sig <= '1' when (rand_int mod 2) = 1 else '0';
    end procedure;
    
    -- Check if random condition is true (for enable)
    function random_enable return boolean is
      variable r : real;
      variable i : integer;
    begin
      uniform(seed1, seed2, r);
      i := integer(floor(r * 4.0));
      return (i = 0);
    end function;
    
  begin
    -- Initialize
    enable <= '0';
    ABC <= "000";
    S <= 'X';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("A 3-input AND gate");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test sequence (programming AND gate: 10000000)
    wait until rising_edge(clk);
    -- @(posedge clk);
    
    wait until rising_edge(clk);
    enable <= '1';
    S <= '1';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    S <= '0';
    
    wait until rising_edge(clk);
    enable <= '0';
    S <= 'X';
    ABC <= "101";  -- 5
    
    wait until rising_edge(clk);
    ABC <= "110";  -- 6
    
    wait until rising_edge(clk);
    ABC <= "111";  -- 7
    
    wait until rising_edge(clk);
    ABC <= "000";  -- 0
    
    wait until rising_edge(clk);
    ABC <= "001";  -- 1
    
    -- Matches Verilog: @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(500) @(posedge clk, negedge clk)
    for i in 1 to 500 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- {A,B,C,S} <= $random;
      random_4bit(S);
      
      -- enable <= ($random&3) == 0;
      enable <= '1' when random_enable else '0';
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;