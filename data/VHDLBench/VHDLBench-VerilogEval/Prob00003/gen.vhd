-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Constant One Output Test
-- No inputs to generate, just controls simulation timing
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    -- Wavedrom control (simplified, not functional in VHDL)
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
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start("Output should be 1");
    wavedrom_start("Output should be 1");
    
    -- Matches Verilog: repeat(20) @(posedge clk, negedge clk);
    for i in 1 to 20 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
    end loop;
    
    wavedrom_stop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;