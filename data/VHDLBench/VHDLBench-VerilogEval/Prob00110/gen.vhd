-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for Moore State Machine (JK-like FSM)
-- Tests reset functionality and state transitions
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    j               : out std_logic;
    k               : out std_logic;
    areset          : out std_logic;
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic := '1';
begin

  areset <= reset;

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
    
    -- Random integer 0-7
    function random_int_0_7 return integer is
      variable rval : real;
    begin
      uniform(seed1, seed2, rval);
      return integer(floor(rval * 8.0));
    end function;
    
    -- Reset test task (matches Verilog reset_test)
    procedure reset_test(async : boolean := false) is
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
      
      -- Note: Diagnostic messages handled in testbench report
    end procedure;
    
    -- Wavedrom tasks (simplified)
    procedure wavedrom_start(title : string := "") is
    begin
      wavedrom_enable <= '1';
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
    -- Predetermined test data (matches Verilog: reg [0:11][1:0] d = 24'b...)
    type test_vector_array is array (0 to 11) of std_logic_vector(1 downto 0);
    constant test_data : test_vector_array := (
      "00", "01", "01", "01", "00", "10", "10", "10", "11", "11", "11", "11"
    );
    
  begin
    -- Initialize
    reset <= '1';
    j <= '0';
    k <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Initial sequence
    wait until rising_edge(clk);
    reset <= '0';
    j <= '1';
    
    wait until rising_edge(clk);
    j <= '0';
    
    -- Wavedrom section: "Reset and transitions"
    wavedrom_start("Reset and transitions");
    reset_test(async => true);
    
    -- Apply predetermined test vectors
    -- Matches Verilog: for (int i=0;i<12;i++) @(posedge clk) {k, j} <= d[i];
    for i in 0 to 11 loop
      wait until rising_edge(clk);
      k <= test_data(i)(1);
      j <= test_data(i)(0);
    end loop;
    
    wavedrom_stop;
    
    -- Random test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      random_bit(j);
      random_bit(k);
      
      -- Matches Verilog: reset <= !($random & 7);
      reset <= '0' when (random_int_0_7 /= 0) else '1';
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;