-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Cellphone Ringer/Motor Control Test
-- Generates sequential test patterns for ring and vibrate_mode inputs
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    ring           : out std_logic;
    vibrate_mode   : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  -- Helper signal for 2-bit concatenation
  signal inputs : std_logic_vector(1 downto 0);
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {vibrate_mode, ring}
  vibrate_mode <= inputs(1);
  ring         <= inputs(0);

  stimulus_process : process
    variable count : integer := 0;
  begin
    -- Initialize
    inputs <= "00";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: wavedrom_start();
    wavedrom_enable <= '1';
    
    -- Matches Verilog: repeat(10) @(posedge clk) {vibrate_mode,ring} <= count++;
    for i in 0 to 9 loop
      wait until rising_edge(clk);
      inputs <= std_logic_vector(to_unsigned(count, 2));
      count := count + 1;
    end loop;
    
    -- Matches Verilog: wavedrom_stop();
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;