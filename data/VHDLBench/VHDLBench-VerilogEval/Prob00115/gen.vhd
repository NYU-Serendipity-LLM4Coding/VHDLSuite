-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 64-bit Arithmetic Shift Register Test
-- Generates predetermined test sequences followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    load           : out std_logic;
    ena            : out std_logic;
    amount         : out std_logic_vector(1 downto 0);
    data           : out std_logic_vector(63 downto 0);
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
    
    -- Random 2-bit generator
    procedure random_2bit(signal sig : out std_logic_vector(1 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 2));
    end procedure;
    
    -- Random 64-bit generator
    procedure random_64bit(signal sig : out std_logic_vector(63 downto 0)) is
      variable rand_low, rand_high : integer;
    begin
      uniform(seed1, seed2, rand_val);
      rand_low := integer(floor(rand_val * 4294967296.0)) mod 65536;
      uniform(seed1, seed2, rand_val);
      rand_high := integer(floor(rand_val * 4294967296.0)) mod 65536;
      uniform(seed1, seed2, rand_val);
      sig(15 downto 0) <= std_logic_vector(to_unsigned(rand_low, 16));
      sig(31 downto 16) <= std_logic_vector(to_unsigned(integer(floor(rand_val * 65536.0)), 16));
      uniform(seed1, seed2, rand_val);
      sig(47 downto 32) <= std_logic_vector(to_unsigned(integer(floor(rand_val * 65536.0)), 16));
      sig(63 downto 48) <= std_logic_vector(to_unsigned(rand_high, 16));
    end procedure;
    
    -- Random boolean (for load and ena)
    procedure random_bool(signal sig : out std_logic; threshold : real) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val < threshold else '0';
    end procedure;
    
  begin
    -- Initialize
    load <= '1';
    ena <= '0';
    data <= (others => 'X');
    amount <= "00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Test sequence 1: Basic shifting
    -- Matches Verilog: @(posedge clk) data <= 64'h000100;
    wait until rising_edge(clk);
    -- 64'h000100 = 24-bit value 0x000100, extended to 64 bits
    data <= std_logic_vector(resize(unsigned'(x"000100"), 64));
    
    -- Wavedrom start "Shifting"
    wavedrom_enable <= '1';
    
    -- Matches Verilog: @(posedge clk) load <= 0; ena <= 1; amount <= 2;
    wait until rising_edge(clk);
    load <= '0';
    ena <= '1';
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "01";  -- 2'b01
    
    wait until rising_edge(clk);
    amount <= "01";  -- 2'b01
    
    wait until rising_edge(clk);
    amount <= "00";  -- 2'b00
    
    wait until rising_edge(clk);
    amount <= "00";  -- 2'b00
    
    wait until rising_edge(clk);
    amount <= "11";  -- 2'b11
    
    wait until rising_edge(clk);
    amount <= "11";  -- 2'b11
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Test sequence 2: Arithmetic right shift
    -- Matches Verilog: @(posedge clk); load <= 1; data <= 64'hx;
    wait until rising_edge(clk);
    load <= '1';
    data <= (others => 'X');
    
    -- Matches Verilog: @(posedge clk); load <= 1; data <= 64'h80000000_00000000;
    wait until rising_edge(clk);
    load <= '1';
    data <= x"8000000000000000";
    
    -- Wavedrom start "Arithmetic right shift"
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    load <= '0';
    ena <= '1';
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until rising_edge(clk);
    amount <= "10";  -- 2'b10
    
    wait until falling_edge(clk);
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Random test: repeat(4000) @(posedge clk, negedge clk)
    -- Matches Verilog:
    --   load <= !($random & 31);
    --   ena <= |($random & 15);
    --   amount <= $random;
    --   data <= {$random,$random};
    for i in 1 to 4000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- load: ~1/32 probability
      random_bool(load, 1.0/32.0);
      
      -- ena: random 4 bits, OR reduction (high probability)
      random_bool(ena, 15.0/16.0);
      
      -- amount: random 2 bits
      random_2bit(amount);
      
      -- data: random 64 bits
      random_64bit(data);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;