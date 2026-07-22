-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Keyboard Scancode Decoder Test
-- Generates predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    code            : out std_logic_vector(7 downto 0);
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
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
    
    -- Random 8-bit vector generator (replaces Verilog $random/$urandom)
    procedure random_byte(signal sig : out std_logic_vector(7 downto 0)) is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 256.0));
      sig <= std_logic_vector(to_unsigned(rand_int, 8));
    end procedure;
    
    -- Apply 8-bit test vector
    procedure apply_vector(vec : std_logic_vector(7 downto 0)) is
    begin
      code <= vec;
    end procedure;
    
  begin
    -- Initialize
    code <= x"45";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("Decode scancodes");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test sequence
    wait until rising_edge(clk);
    apply_vector(x"45");  -- 8'h45
    
    wait until rising_edge(clk);
    apply_vector(x"03");  -- 8'h03
    
    wait until rising_edge(clk);
    apply_vector(x"46");  -- 8'h46
    
    wait until rising_edge(clk);
    apply_vector(x"16");  -- 8'h16
    
    wait until rising_edge(clk);
    apply_vector(x"1a");  -- 8'd26 = 0x1a
    
    wait until rising_edge(clk);
    apply_vector(x"1e");  -- 8'h1e
    
    wait until rising_edge(clk);
    apply_vector(x"25");  -- 8'h25
    
    wait until rising_edge(clk);
    apply_vector(x"26");  -- 8'h26
    
    wait until rising_edge(clk);
    apply_vector(x"2e");  -- 8'h2e
    
    wait until rising_edge(clk);
    random_byte(code);  -- $random
    
    wait until rising_edge(clk);
    apply_vector(x"36");  -- 8'h36
    
    wait until rising_edge(clk);
    random_byte(code);  -- $random
    
    wait until rising_edge(clk);
    apply_vector(x"3d");  -- 8'h3d
    
    wait until rising_edge(clk);
    apply_vector(x"3e");  -- 8'h3e
    
    wait until rising_edge(clk);
    apply_vector(x"45");  -- 8'h45
    
    wait until rising_edge(clk);
    apply_vector(x"46");  -- 8'h46
    
    wait until rising_edge(clk);
    random_byte(code);  -- $random
    
    wait until rising_edge(clk);
    random_byte(code);  -- $random
    
    wait until rising_edge(clk);
    random_byte(code);  -- $random
    
    wait until rising_edge(clk);
    random_byte(code);  -- $random
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(1000) @(posedge clk, negedge clk)
    for i in 1 to 1000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_byte(code);
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;