-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Moore State Machine Next-State Logic Test
-- Generates random inputs and one-hot state vectors
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    d              : out std_logic;
    done_counting  : out std_logic;
    ack            : out std_logic;
    state          : out std_logic_vector(9 downto 0);
    tb_match       : in  boolean;
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
    variable temp_vec : std_logic_vector(2 downto 0);
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random 3-bit vector
    procedure random_3bits(signal sig : out std_logic_vector(2 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 8.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 3));
    end procedure;
    
    -- Generate one-hot state (1 << random position 0..9)
    procedure random_onehot_state(signal sig : out std_logic_vector(9 downto 0)) is
      variable pos : integer;
    begin
      uniform(seed1, seed2, rand_val);
      pos := integer(floor(rand_val * 10.0));
      if pos > 9 then pos := 9; end if;
      sig <= std_logic_vector(shift_left(to_unsigned(1, 10), pos));
    end procedure;
    
  begin
    -- Initialize
    d <= '0';
    done_counting <= '0';
    ack <= '0';
    state <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: repeat(300) @(posedge clk, negedge clk)
    for i in 1 to 300 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- {d, done_counting, ack} = $random;
      random_bit(d);
      random_bit(done_counting);
      random_bit(ack);
      
      -- state <= 1 << ($unsigned($random) % 10);
      random_onehot_state(state);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;