-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Positive Edge Detector Test
-- Generates predetermined test patterns followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    tb_match        : in  boolean;
    signal_in       : out std_logic_vector(7 downto 0);
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Random 8-bit vector generator
    procedure random_vector(signal sig : out std_logic_vector(7 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
    -- Wavedrom tasks (simplified placeholders)
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
    
    -- Matches Verilog: in <= 0;
    signal_in <= "00000000";
    
    -- Matches Verilog: @(posedge clk);
    wait until rising_edge(clk);
    
    -- Start wavedrom
    wavedrom_start("");
    
    -- Matches Verilog: repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: in <= 1;
    signal_in <= "00000001";
    
    -- Matches Verilog: repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: in <= 0;
    signal_in <= "00000000";
    
    -- Matches Verilog: repeat(4) @(negedge clk);
    for i in 1 to 4 loop
      wait until falling_edge(clk);
    end loop;
    
    -- Matches Verilog: in <= 6;
    signal_in <= "00000110";
    
    -- Matches Verilog: repeat(2) @(negedge clk);
    for i in 1 to 2 loop
      wait until falling_edge(clk);
    end loop;
    
    -- Matches Verilog: in <= 0;
    signal_in <= "00000000";
    
    -- Matches Verilog: repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Stop wavedrom
    wavedrom_stop;
    
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk) in <= $random;
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector(signal_in);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;