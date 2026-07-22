-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Edge Detector Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    tb_match       : in  boolean;
    signal_in      : out std_logic_vector(31 downto 0);
    reset          : out std_logic;
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
    
    -- Random 32-bit vector generator
    procedure random_vector(signal vec : out std_logic_vector(31 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * real(2**30))) * 4;  -- Approximate 32-bit random
      vec <= std_logic_vector(to_signed(rand_int, 32));
    end procedure;
    
    -- Random reset generator (matches Verilog: reset <= !($random & 15))
    procedure random_reset(signal rst : out std_logic) is
      variable rand_bits : integer;
    begin
      uniform(seed1, seed2, rand_val);
      rand_bits := integer(floor(rand_val * 16.0));
      rst <= '0' when (rand_bits /= 0) else '1';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= (others => '0');
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: @(posedge clk); reset <= 1; in = 0;
    wait until rising_edge(clk);
    reset <= '1';
    signal_in <= (others => '0');
    
    -- Start wavedrom "Example"
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- repeat(1) @(posedge clk); reset = 0;
    wait until rising_edge(clk);
    reset <= '0';
    
    -- @(posedge clk) in = 32'h2;
    wait until rising_edge(clk);
    signal_in <= x"00000002";
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    -- in = 32'he;
    signal_in <= x"0000000E";
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- in = 0;
    signal_in <= (others => '0');
    
    -- @(posedge clk) in = 32'h2;
    wait until rising_edge(clk);
    signal_in <= x"00000002";
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- reset = 1;
    reset <= '1';
    
    -- @(posedge clk);
    wait until rising_edge(clk);
    
    -- reset = 0; in = 0;
    reset <= '0';
    signal_in <= (others => '0');
    
    -- repeat(3) @(posedge clk);
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Stop wavedrom
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Start second wavedrom section
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- in <= 1;
    signal_in <= x"00000001";
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- in <= 0;
    signal_in <= (others => '0');
    
    -- repeat(2) @(negedge clk);
    for i in 1 to 2 loop
      wait until falling_edge(clk);
    end loop;
    
    -- in <= 6;
    signal_in <= x"00000006";
    
    -- repeat(1) @(negedge clk);
    wait until falling_edge(clk);
    
    -- in <= 0;
    signal_in <= (others => '0');
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- in <= 32'h10;
    signal_in <= x"00000010";
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- reset <= 1;
    reset <= '1';
    
    -- repeat(1) @(posedge clk);
    wait until rising_edge(clk);
    
    -- in <= 32'h0;
    signal_in <= (others => '0');
    
    -- repeat(1) @(posedge clk);
    wait until rising_edge(clk);
    
    -- reset <= 0;
    reset <= '0';
    
    -- repeat(1) @(posedge clk);
    wait until rising_edge(clk);
    
    -- reset <= 1; in <= 32'h20;
    reset <= '1';
    signal_in <= x"00000020";
    
    -- repeat(1) @(posedge clk);
    wait until rising_edge(clk);
    
    -- reset <= 0; in <= 32'h00;
    reset <= '0';
    signal_in <= (others => '0');
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Stop second wavedrom
    wait until falling_edge(clk);
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector(signal_in);
      random_reset(reset);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;