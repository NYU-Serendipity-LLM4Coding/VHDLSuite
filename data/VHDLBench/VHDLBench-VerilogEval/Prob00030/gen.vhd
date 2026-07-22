-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Population Count Test
-- Generates test vectors for 255-bit input
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic_vector(254 downto 0);
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
    variable temp_vec : std_logic_vector(254 downto 0);
    
    -- Generate random 32-bit vector
    procedure random_32bit(variable result : out std_logic_vector(31 downto 0)) is
      variable rand_temp : real;
      variable rand_int_temp : integer;
    begin
      uniform(seed1, seed2, rand_temp);
      rand_int_temp := integer(floor(rand_temp * real(2**30))) * 2;
      if rand_temp > 0.5 then
        rand_int_temp := rand_int_temp + 1;
      end if;
      result := std_logic_vector(to_unsigned(rand_int_temp, 32));
    end procedure;
    
    -- Generate random 255-bit vector (8 x 32-bit chunks, last one is 31 bits)
    procedure random_255bit(signal sig : out std_logic_vector(254 downto 0)) is
      variable chunk : std_logic_vector(31 downto 0);
      variable result : std_logic_vector(254 downto 0);
    begin
      -- Generate 7 complete 32-bit chunks (bits 223:0)
      for i in 0 to 6 loop
        random_32bit(chunk);
        result((i+1)*32-1 downto i*32) := chunk;
      end loop;
      -- Generate last 31-bit chunk (bits 254:224)
      random_32bit(chunk);
      result(254 downto 224) := chunk(30 downto 0);
      sig <= result;
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Predetermined test vectors
    wait until rising_edge(clk);
    signal_in <= (others => '0');  -- 255'h0
    
    wait until falling_edge(clk);
    signal_in <= (others => '0');  -- 255'h0
    
    wait until rising_edge(clk);
    signal_in <= (0 => '1', others => '0');  -- 255'h1
    
    wait until falling_edge(clk);
    signal_in <= (0 => '1', others => '0');  -- 255'h1
    
    wait until rising_edge(clk);
    signal_in <= (1 downto 0 => '1', others => '0');  -- 255'h3
    
    wait until falling_edge(clk);
    signal_in <= (1 downto 0 => '1', others => '0');  -- 255'h3
    
    wait until rising_edge(clk);
    signal_in <= (2 downto 0 => '1', others => '0');  -- 255'h7
    
    wait until falling_edge(clk);
    -- 255'haaaa = 0xaaaa in lower 16 bits = alternating 1010...
    signal_in <= (others => '0');
    signal_in(15 downto 0) <= x"aaaa";
    
    wait until rising_edge(clk);
    -- 255'hf00000 = 0xf00000 in lower 24 bits
    signal_in <= (others => '0');
    signal_in(23 downto 20) <= x"f";
    
    wait until falling_edge(clk);
    signal_in <= (others => '0');  -- 255'h0
    
    wait for 1 ps;
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_255bit(signal_in);
    end loop;
    
    -- Final test vectors
    wait until rising_edge(clk);
    signal_in <= (others => '0');  -- '0
    
    wait until rising_edge(clk);
    signal_in <= (others => '1');  -- '1
    
    wait until rising_edge(clk);
    
    -- Matches Verilog: #1 $finish
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;