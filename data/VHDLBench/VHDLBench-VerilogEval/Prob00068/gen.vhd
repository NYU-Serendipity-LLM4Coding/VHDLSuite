-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-digit BCD Counter Test
-- Generates reset sequences and timing for wavedrom displays
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
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
    
    -- Reset test procedure (simplified from Verilog task)
    procedure reset_test is
      variable arfail, srfail, datafail : boolean;
    begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      
      for i in 1 to 3 loop
        wait until rising_edge(clk);
      end loop;
      
      wait until falling_edge(clk);
      datafail := not tb_match;
      reset <= '1';
      
      wait until rising_edge(clk);
      arfail := not tb_match;
      
      wait until rising_edge(clk);
      srfail := not tb_match;
      reset <= '0';
      
      -- Note: Diagnostic messages omitted in VHDL version
    end procedure;
    
    -- Wavedrom procedures (simplified)
    procedure wavedrom_start is
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
    reset <= '1';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: reset_test();
    reset_test;
    
    -- repeat(2) @(posedge clk);
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    -- @(negedge clk);
    wait until falling_edge(clk);
    
    -- wavedrom_start("Counting");
    wavedrom_start;
    
    -- repeat(12) @(posedge clk);
    for i in 1 to 12 loop
      wait until rising_edge(clk);
    end loop;
    
    -- @(negedge clk);
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- repeat(71) @(posedge clk);
    for i in 1 to 71 loop
      wait until rising_edge(clk);
    end loop;
    
    -- @(negedge clk) wavedrom_start("100 rollover");
    wait until falling_edge(clk);
    wavedrom_start;
    
    -- repeat(16) @(posedge clk);
    for i in 1 to 16 loop
      wait until rising_edge(clk);
    end loop;
    
    -- @(negedge clk) wavedrom_stop();
    wait until falling_edge(clk);
    wavedrom_stop;
    
    -- repeat(400) @(posedge clk, negedge clk) reset <= !($random & 31);
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      uniform(seed1, seed2, rand_val);
      if integer(floor(rand_val * 32.0)) /= 0 then
        reset <= '0';
      else
        reset <= '1';
      end if;
    end loop;
    
    -- repeat(19590) @(posedge clk);
    for i in 1 to 19590 loop
      wait until rising_edge(clk);
    end loop;
    
    -- reset <= 1'b1;
    reset <= '1';
    
    -- repeat(5) @(posedge clk);
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    -- #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;