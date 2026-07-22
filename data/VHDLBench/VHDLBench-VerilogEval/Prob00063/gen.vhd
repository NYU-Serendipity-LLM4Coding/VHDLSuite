-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Shift/Counter Register Test
-- Generates control signals and data for shift and count operations
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    shift_ena       : out std_logic;
    count_ena       : out std_logic;
    data            : out std_logic;
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
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random control generator (0, 1, or 2 for shift_ena/count_ena combinations)
    procedure random_control is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 3.0));
      case rand_int is
        when 0 =>
          shift_ena <= '0';
          count_ena <= '0';
        when 1 =>
          shift_ena <= '1';
          count_ena <= '0';
        when others =>
          shift_ena <= '0';
          count_ena <= '1';
      end case;
    end procedure;
    
  begin
    -- Initialize
    data <= '0';
    shift_ena <= '1';
    count_ena <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Matches Verilog: repeat(5) @(posedge clk);
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    -- Matches Verilog: data <= 1; shift_ena <= 0; count_ena <= 0; @(posedge clk);
    data <= '1';
    shift_ena <= '0';
    count_ena <= '0';
    wait until rising_edge(clk);
    
    -- Wavedrom start: "Shift mode"
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    shift_ena <= '1';
    
    wait until rising_edge(clk);
    shift_ena <= '0';
    wait until rising_edge(clk);
    -- repeat(2) already done above (1 more)
    
    wait until rising_edge(clk);
    shift_ena <= '1';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    wait until rising_edge(clk);
    data <= '0';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    -- wavedrom_stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Second test section: Count mode
    data <= '1';
    shift_ena <= '1';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    shift_ena <= '0';
    
    -- Wavedrom start: "Count mode"
    wavedrom_enable <= '1';
    
    wait until rising_edge(clk);
    count_ena <= '1';
    
    wait until rising_edge(clk);
    count_ena <= '0';
    wait until rising_edge(clk);
    -- repeat(2) already done above (1 more)
    
    wait until rising_edge(clk);
    count_ena <= '1';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    wait until rising_edge(clk);
    data <= '0';
    
    -- repeat(4) @(posedge clk);
    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    -- wavedrom_stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(2000) @(posedge clk, negedge clk)
    for i in 1 to 2000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_control;
      random_bit(data);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;