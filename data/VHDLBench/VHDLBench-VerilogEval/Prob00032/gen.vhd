-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Vector Splitter Test
-- Generates sequential 3-bit vectors (0 to 9)
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    vec            : out std_logic_vector(2 downto 0);
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable count : integer := 0;
    
    -- Wavedrom tasks (simplified, not functional in VHDL)
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
    vec <= "000";
    wavedrom_enable <= '0';
    sim_done <= false;
    count := 0;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: @(negedge clk);
    wait until falling_edge(clk);
    
    wavedrom_start;
    
    -- Matches Verilog: repeat(10) @(posedge clk) vec <= count++;
    for i in 1 to 10 loop
      wait until rising_edge(clk);
      vec <= std_logic_vector(to_unsigned(count, 3));
      count := count + 1;
    end loop;
    
    wavedrom_stop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;