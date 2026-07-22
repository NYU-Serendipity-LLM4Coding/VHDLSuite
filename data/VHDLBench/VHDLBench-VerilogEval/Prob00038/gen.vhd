-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-bit Counter Test
-- Tests reset functionality and normal counting operation
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    reset           : out std_logic;
    tb_match        : in  boolean;
    wavedrom_enable : out std_logic;
    wavedrom_title  : out string(1 to 512);
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable arfail   : boolean;
    variable srfail   : boolean;
    variable datafail : boolean;
    
    -- Wavedrom control (simplified)
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
      
      -- @(negedge clk) begin datafail = !tb_match; reset <= 1; end
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
      
      -- Display hints (simplified - in real implementation would use report)
      if srfail then
        report "Hint: Your reset doesn't seem to be working." severity note;
      elsif arfail and not datafail then
        report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
      end if;
    end procedure;
    
  begin
    -- Initialize
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- @(negedge clk);
    wait until falling_edge(clk);
    
    -- Wavedrom section: "Reset and counting"
    wavedrom_start("Reset and counting");
    reset_test;
    
    -- repeat(3) @(posedge clk);
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    
    wavedrom_stop;
    
    -- Main test: repeat(400) @(posedge clk, negedge clk)
    -- Randomly assert reset (Verilog: reset <= !($random & 31))
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate random reset (approximately 1/32 probability)
      uniform(seed1, seed2, rand_val);
      if rand_val < 0.03125 then  -- 1/32 = 0.03125
        reset <= '1';
      else
        reset <= '0';
      end if;
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;