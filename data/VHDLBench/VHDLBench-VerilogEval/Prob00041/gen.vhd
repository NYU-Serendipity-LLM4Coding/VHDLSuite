-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 8-bit D Flip-Flop with Synchronous Reset
-- Tests reset functionality and random data patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    d               : out std_logic_vector(7 downto 0);
    reset           : out std_logic;
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
    variable arfail   : boolean;
    variable srfail   : boolean;
    variable datafail : boolean;
    
    -- Random 8-bit vector generator
    procedure random_byte(signal sig : out std_logic_vector(7 downto 0)) is
      variable temp_rand : real;
      variable temp_int  : integer;
    begin
      uniform(seed1, seed2, temp_rand);
      temp_int := integer(floor(temp_rand * 256.0));
      sig <= std_logic_vector(to_unsigned(temp_int, 8));
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
    
    -- Reset test task (matches Verilog reset_test)
    procedure reset_test is
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      -- repeat(3) @(posedge clk);
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      -- @(negedge clk) begin datafail = !tb_match ; reset <= 1; end
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      -- @(posedge clk) arfail = !tb_match;
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      -- @(posedge clk) begin srfail = !tb_match; reset <= 0; end
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      -- Error reporting
      if srfail then
        report "Hint: Your reset doesn't seem to be working." severity note;
      elsif arfail and (false or not datafail) then
        -- async=0, so checking for synchronous reset
        report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
      end if;
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    random_byte(d);
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Wavedrom section: "Synchronous active-high reset"
    wavedrom_start("Synchronous active-high reset");
    reset_test;
    
    -- repeat(10) @(negedge clk)
    for i in 1 to 10 loop
      wait until falling_edge(clk);
      random_byte(d);
    end loop;
    
    wavedrom_stop;
    
    -- Main test: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- reset <= !($random & 15);
      -- This creates reset with occasional pulses (15/16 chance of 0)
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      if rand_int /= 0 then
        reset <= '0';
      else
        reset <= '1';
      end if;
      
      random_byte(d);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;