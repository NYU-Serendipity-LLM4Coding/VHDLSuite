-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for One-Hot State Machine Test
-- Generates state and input vectors for testing state transition logic
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk              : in  std_logic;
    signal_in        : out std_logic;
    state            : out std_logic_vector(9 downto 0);
    tb_match         : in  boolean;
    next_state_ref   : in  std_logic_vector(9 downto 0);
    next_state_dut   : in  std_logic_vector(9 downto 0);
    wavedrom_title   : out string(1 to 512);
    wavedrom_enable  : out std_logic;
    sim_done         : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal state_error : std_logic_vector(9 downto 0) := (others => '0');
begin

  -- Track errors in next_state bits
  -- Matches Verilog: always @(posedge clk, negedge clk)
  --   state_error <= state_error | (next_state_ref^next_state_dut);
  error_tracking : process(clk)
    variable init_count : integer := 0;
  begin
    if rising_edge(clk) or falling_edge(clk) then
      -- Skip first 2 clock edges (matches Verilog: repeat(2) @(posedge clk))
      if init_count < 2 then
        init_count := init_count + 1;
      else
        state_error <= state_error or (next_state_ref xor next_state_dut);
      end if;
    end if;
  end process;

  stimulus_process : process
    variable seed1    : positive := 54321;
    variable seed2    : positive := 98765;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random integer in range [0, max_val)
    procedure random_int_range(variable result : out integer; max_val : integer) is
    begin
      uniform(seed1, seed2, rand_val);
      result := integer(floor(rand_val * real(max_val)));
    end procedure;
    
  begin
    -- Initialize
    state <= (others => '0');
    signal_in <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- Wait for 2 clock cycles
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Start wavedrom
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Test each state with in=0
    -- Matches Verilog: for (int i=0;i<10;i++) state <= 1<<i; in <= 0;
    for i in 0 to 9 loop
      if (i mod 2) = 0 then
        wait until falling_edge(clk);
      else
        wait until rising_edge(clk);
      end if;
      state <= std_logic_vector(shift_left(to_unsigned(1, 10), i));
      signal_in <= '0';
    end loop;
    
    -- Test each state with in=1
    for i in 0 to 9 loop
      if ((i + 10) mod 2) = 0 then
        wait until falling_edge(clk);
      else
        wait until rising_edge(clk);
      end if;
      state <= std_logic_vector(shift_left(to_unsigned(1, 10), i));
      signal_in <= '1';
    end loop;
    
    -- Stop wavedrom
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random one-hot tests
    -- Matches Verilog: repeat(200) state <= 1<<($unsigned($random)%10); in <= $random;
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      random_int_range(rand_int, 10);
      state <= std_logic_vector(shift_left(to_unsigned(1, 10), rand_int));
      random_bit(signal_in);
    end loop;
    
    -- Display hints for each next_state bit
    -- Matches Verilog: for (int i=0;i<$bits(state_error);i++)
    --   $display("Hint: next_state[%0d] is %s.", i, ...);
    wait for 1 ps;
    for i in 0 to 9 loop
      if state_error(i) = '0' then
        report "Hint: next_state[" & integer'image(i) & "] is correct.";
      else
        report "Hint: next_state[" & integer'image(i) & "] is incorrect.";
      end if;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;