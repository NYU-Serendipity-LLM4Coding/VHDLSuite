-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Lemmings FSM Test
-- Generates reset tests, predetermined test sequence, and random tests
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
  
  -- Predetermined test data (matches Verilog array d)
  type test_data_t is array (0 to 13) of std_logic_vector(3 downto 0);
  constant d : test_data_t := (
    x"2", x"2", x"3", x"2", x"a", x"2", x"0",
    x"0", x"0", x"3", x"2", x"2", x"2", x"2"
  );
  
begin

  areset <= reset;

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    variable rand_vec : std_logic_vector(31 downto 0);
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Generate random 32-bit vector
    procedure random_vector(variable vec : out std_logic_vector(31 downto 0)) is
    begin
      for i in 0 to 31 loop
        uniform(seed1, seed2, rand_val);
        vec(i) := '1' when rand_val > 0.5 else '0';
      end loop;
    end procedure;
    
    -- Reset test task (matches Verilog reset_test)
    procedure reset_test(async : boolean := false) is
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
      
      -- Note: Display messages would be shown in console during simulation
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    bump_left <= '0';
    bump_right <= '1';
    ground <= '0';
    dig <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- First reset test
    reset_test(true);
    
    -- Second reset sequence
    reset <= '1';
    wait until rising_edge(clk);
    reset <= '0';
    
    -- Predetermined test sequence: "Digging"
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    for i in 0 to 13 loop
      wait until rising_edge(clk);
      -- d[i] = {bump_left, bump_right, ground, dig}
      bump_left  <= d(i)(3);
      bump_right <= d(i)(2);
      ground     <= d(i)(1);
      dig        <= d(i)(0);
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
      
      -- Generate random values
      random_vector(rand_vec);
      
      -- {dig, bump_right, bump_left} <= $random & $random;
      dig        <= rand_vec(0) and rand_vec(16);
      bump_right <= rand_vec(1) and rand_vec(17);
      bump_left  <= rand_vec(2) and rand_vec(18);
      
      -- ground <= |($random & 7);
      random_vector(rand_vec);
      ground <= rand_vec(0) or rand_vec(1) or rand_vec(2);
      
      -- reset <= !($random & 31);
      random_vector(rand_vec);
      reset <= not (rand_vec(0) and rand_vec(1) and rand_vec(2) and 
                    rand_vec(3) and rand_vec(4));
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;