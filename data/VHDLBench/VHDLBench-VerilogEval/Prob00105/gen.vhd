-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 100-bit Rotator Test
-- Generates random load, ena, and data signals
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    load     : out std_logic;
    ena      : out std_logic_vector(1 downto 0);
    data     : out std_logic_vector(99 downto 0);
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  -- Matches Verilog: always @(posedge clk) data <= {$random,$random,$random,$random};
  -- Generate random 100-bit data on every clock edge
  data_gen_process : process(clk)
    variable seed1 : positive := 12345;
    variable seed2 : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    variable temp_data : std_logic_vector(99 downto 0);
    variable temp_vec : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      -- Generate 100 bits using multiple random calls (32 bits each, need 4 calls)
      for i in 0 to 3 loop
        uniform(seed1, seed2, rand_val);
        rand_int := integer(floor(rand_val * real(2**31)));
        temp_vec := std_logic_vector(to_signed(rand_int, 32));
        
        if i < 3 then
          temp_data((i+1)*32-1 downto i*32) := temp_vec;
        else
          -- Last chunk: only 4 bits needed (100 - 96 = 4)
          temp_data(99 downto 96) := temp_vec(3 downto 0);
        end if;
      end loop;
      data <= temp_data;
    end if;
  end process;

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    variable rand_int : integer;
  begin
    -- Initialize
    load <= '0';
    ena <= "00";
    sim_done <= false;
    
    -- Matches Verilog: initial begin load <= 1;
    load <= '1';
    
    -- Wait for 3 posedge clk
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- Matches Verilog: repeat(4000) @(posedge clk, negedge clk)
    for i in 1 to 4000 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- load <= !($random & 31);
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * real(2**31)));
      -- If (rand_int & 31) == 0, then load = 1, else load = 0
      if (rand_int mod 32) = 0 then
        load <= '1';
      else
        load <= '0';
      end if;
      
      -- ena <= $random;
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 4.0));  -- 0 to 3
      ena <= std_logic_vector(to_unsigned(rand_int, 2));
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;