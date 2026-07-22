-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Lemmings FSM Test
-- Provides comprehensive test sequence for walking, falling, digging, and splatting
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    areset          : out std_logic;
    bump_left       : out std_logic;
    bump_right      : out std_logic;
    ground          : out std_logic;
    dig             : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic;
  signal inputs : std_logic_vector(3 downto 0);  -- {dig, ground, bump_right, bump_left}
begin

  areset <= reset;
  
  -- Split inputs vector
  dig        <= inputs(3);
  ground     <= inputs(2);
  bump_right <= inputs(1);
  bump_left  <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 4-bit test vector {dig, ground, bump_right, bump_left}
    procedure apply_inputs(vec : integer) is
    begin
      inputs <= std_logic_vector(to_unsigned(vec, 4));
    end procedure;
    
    -- Random input generation (matches Verilog $random & $random)
    procedure random_inputs is
      variable r1, r2, r3 : real;
      variable v1, v2, v3 : unsigned(7 downto 0);
      variable result : unsigned(7 downto 0);
    begin
      uniform(seed1, seed2, r1);
      uniform(seed1, seed2, r2);
      uniform(seed1, seed2, r3);
      
      v1 := to_unsigned(integer(floor(r1 * 256.0)), 8);
      v2 := to_unsigned(integer(floor(r2 * 256.0)), 8);
      v3 := to_unsigned(integer(floor(r3 * 256.0)), 8);
      
      -- Bitwise AND in VHDL for unsigned types
      result := v1 and v2;
      
      dig        <= result(0);  -- LSB
      bump_right <= result(1);
      bump_left  <= result(2);
      
      -- ground <= |($random & 7) - means ground=1 if any bit of (random & 7) is set
      result := v3 and "00000111";
      ground <= '1' when (result /= "00000000") else '0';
    end procedure;
    
    procedure random_reset is
      variable r : real;
      variable v : unsigned(4 downto 0);
    begin
      uniform(seed1, seed2, r);
      v := to_unsigned(integer(floor(r * 32.0)), 5);
      reset <= '0' when (v /= "00000") else '1';
    end procedure;
    
  begin
    -- Initialize
    reset  <= '1';
    inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait until rising_edge(clk);
    reset <= '0';
    apply_inputs(2);  -- {bump_left, bump_right, ground, dig} = 0010
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    apply_inputs(3);
    
    wait until rising_edge(clk);
    apply_inputs(2);
    
    wait until rising_edge(clk);
    apply_inputs(10);
    
    wait until rising_edge(clk);
    apply_inputs(2);
    
    wait until rising_edge(clk);
    apply_inputs(0);
    
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    apply_inputs(3);
    wait until rising_edge(clk);
    apply_inputs(2);
    
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Fall and survive (20 cycles)
    apply_inputs(0);
    for i in 1 to 20 loop
      wait until rising_edge(clk);
    end loop;
    apply_inputs(2);
    wait until rising_edge(clk);
    
    -- Fall and splat (21 cycles falling left)
    apply_inputs(0);
    for i in 1 to 21 loop
      wait until rising_edge(clk);
    end loop;
    apply_inputs(2);
    
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      random_inputs;
    end loop;
    
    -- Reset and fall right, then splat
    reset <= '1';
    apply_inputs(2);
    wait until rising_edge(clk);
    reset <= '0';
    bump_left <= '1';
    
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    apply_inputs(0);
    for i in 1 to 21 loop
      wait until rising_edge(clk);
    end loop;
    apply_inputs(2);
    
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      random_inputs;
    end loop;
    
    -- Test 24-cycle fall
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '0';
    apply_inputs(2);
    wavedrom_enable <= '1';
    wait until rising_edge(clk);
    apply_inputs(0);
    
    for i in 1 to 24 loop
      wait until rising_edge(clk);
    end loop;
    apply_inputs(2);
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Test 35-cycle fall (5-bit counter test)
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '0';
    apply_inputs(2);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    apply_inputs(0);
    
    for i in 1 to 35 loop
      wait until rising_edge(clk);
    end loop;
    apply_inputs(2);
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      random_inputs;
    end loop;
    
    -- Test 67-cycle fall (6-bit counter test)
    reset <= '1';
    apply_inputs(2);
    wait until rising_edge(clk);
    reset <= '0';
    wait until rising_edge(clk);
    apply_inputs(0);
    
    for i in 1 to 67 loop
      wait until rising_edge(clk);
    end loop;
    apply_inputs(2);
    
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      random_inputs;
    end loop;
    
    -- Final reset and random testing
    reset <= '1';
    apply_inputs(2);
    wait until rising_edge(clk);
    reset <= '0';
    
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_inputs;
      random_reset;
    end loop;
    
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;