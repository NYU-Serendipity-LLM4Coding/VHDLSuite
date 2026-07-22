-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 1101 Sequence Detector FSM
-- Tests reset functionality and sequence detection
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    reset          : out std_logic;
    data           : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    tb_match       : in  boolean;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random reset generator (matches Verilog: !($random & 31))
    procedure random_reset(signal sig : out std_logic) is
      variable rand_int : integer;
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      sig <= '0' when (rand_int /= 0) else '1';
    end procedure;
    
    -- Reset test task (matches Verilog reset_test task)
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
      
      if srfail then
        report "Hint: Your reset doesn't seem to be working." severity note;
      elsif arfail and (false or not datafail) then
        report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
      end if;
    end procedure;
    
    -- Wavedrom procedures (simplified)
    procedure wavedrom_start(title : string) is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
    -- Test sequence: 10'b1110110011
    type bit_array is array (0 to 9) of std_logic;
    constant d : bit_array := ('1','1','1','0','1','1','0','0','1','1');
    
  begin
    -- Initialize
    reset <= '1';
    data <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial reset sequence
    wait until rising_edge(clk);
    reset <= '0';
    data <= '1';
    
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    
    data <= '0';
    wait until rising_edge(clk);
    data <= '1';
    wait until rising_edge(clk);
    data <= '0';
    
    -- Wavedrom section
    wavedrom_start("Reset and sequence detect");
    reset_test;
    
    -- Apply test sequence
    for i in 0 to 9 loop
      wait until rising_edge(clk);
      data <= d(i);
    end loop;
    
    wavedrom_stop;
    
    -- Random testing: repeat(600) @(posedge clk, negedge clk)
    for i in 1 to 600 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_reset(reset);
      random_bit(data);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;