-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for One-Hot State Machine Test
-- Generates random one-hot states and input signals
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    signal_in : out std_logic;
    state    : out std_logic_vector(3 downto 0);
    tb_match : in  boolean;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

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
    
    -- Generate one-hot state (1 << (random % 4))
    procedure random_onehot_state(signal sig : out std_logic_vector(3 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      case rand_int is
        when 0 => sig <= "0001";  -- 1 << 0
        when 1 => sig <= "0010";  -- 1 << 1
        when 2 => sig <= "0100";  -- 1 << 2
        when others => sig <= "1000";  -- 1 << 3
      end case;
    end procedure;
    
  begin
    -- Initialize
    signal_in <= '0';
    state <= "0001";
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    -- Test the one-hot cases first
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      random_onehot_state(state);
      random_bit(signal_in);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;