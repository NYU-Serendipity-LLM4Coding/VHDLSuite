-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Byte Reversal Test
-- Generates random 32-bit input vectors
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic_vector(31 downto 0);
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
    
    -- Generate random 32-bit vector (replaces Verilog $random)
    procedure random_vector(signal sig : out std_logic_vector(31 downto 0)) is
      variable temp : unsigned(31 downto 0);
    begin
      -- Generate 32 bits using multiple random calls
      for i in 0 to 3 loop
        uniform(seed1, seed2, rand_val);
        rand_int := integer(floor(rand_val * 256.0));
        temp(i*8+7 downto i*8) := to_unsigned(rand_int, 8);
      end loop;
      sig <= std_logic_vector(temp);
    end procedure;
    
    -- Wavedrom tasks (simplified)
    procedure wavedrom_start(title : string) is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Wavedrom section: "Random inputs"
    wavedrom_start("Random inputs");
    
    -- Matches Verilog: repeat(10) @(posedge clk, negedge clk)
    for i in 1 to 10 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector(signal_in);
    end loop;
    
    wavedrom_stop;
    
    -- Main test: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector(signal_in);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;