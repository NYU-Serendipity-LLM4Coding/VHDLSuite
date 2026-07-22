-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 4-bit Shift Register Test
-- Tests asynchronous reset, load, and enable functionality
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk             : in  std_logic;
    areset          : out std_logic;
    load            : out std_logic;
    ena             : out std_logic;
    data            : out std_logic_vector(3 downto 0);
    wavedrom_title  : out string(1 to 512);
    wavedrom_enable : out std_logic;
    tb_match        : in  boolean;
    sim_done        : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  signal reset : std_logic := '0';
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
    
    -- Random vector generator
    procedure random_vector(signal sig : out std_logic_vector) is
      variable temp : unsigned(sig'length - 1 downto 0);
    begin
      for i in temp'range loop
        uniform(seed1, seed2, rand_val);
        temp(i) := '1' when rand_val > 0.5 else '0';
      end loop;
      sig <= std_logic_vector(temp);
    end procedure;
    
    -- Reset test task (matches Verilog reset_test)
    procedure reset_test(async : boolean := false) is
      variable arfail   : boolean;
      variable srfail   : boolean;
      variable datafail : boolean;
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
      elsif arfail and (async or not datafail) then
        if async then
          report "Hint: Your reset should be asynchronous, but doesn't appear to be." severity note;
        else
          report "Hint: Your reset should be synchronous, but doesn't appear to be." severity note;
        end if;
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
    
  begin
    -- Initialize
    load  <= '1';
    ena   <= '0';
    reset <= '1';
    data  <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: {load, ena, reset, data} <= 7'h40;
    wait until rising_edge(clk);
    load  <= '1';
    ena   <= '0';
    reset <= '0';
    data  <= "1111";
    
    -- Start wavedrom
    wavedrom_start("Load and reset");
    
    -- Matches Verilog: @(posedge clk) {load, ena, reset, data} <= 7'h0x;
    wait until rising_edge(clk);
    load  <= '0';
    ena   <= '0';
    reset <= '0';
    -- data is don't care (x)
    
    wait until rising_edge(clk);
    load  <= '0';
    ena   <= '1';
    reset <= '0';
    
    wait until rising_edge(clk);
    load  <= '0';
    ena   <= '1';
    reset <= '0';
    
    wait until rising_edge(clk);
    load  <= '0';
    ena   <= '0';
    reset <= '0';
    
    -- Reset test with async=1
    reset_test(async => true);
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    wavedrom_stop;
    
    -- Random testing: repeat(400) @(posedge clk, negedge clk)
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- reset <= !($random & 31);
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      reset <= '0' when (rand_int /= 0) else '1';
      
      -- load <= !($random & 15);
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      load <= '0' when (rand_int /= 0) else '1';
      
      -- ena <= |($random & 31);
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 32.0));
      ena <= '1' when (rand_int /= 0) else '0';
      
      -- data <= $random;
      random_vector(data);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;