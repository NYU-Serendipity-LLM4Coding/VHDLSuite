-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for State Machine Next-State Logic Test
-- First tests one-hot encodings, then semi-random patterns
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk      : in  std_logic;
    y        : out std_logic_vector(5 downto 0);
    w        : out std_logic;
    tb_match : in  boolean;
    sim_done : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1       : positive := 12345;
    variable seed2       : positive := 67890;
    variable rand_val    : real;
    variable rand_int    : integer;
    variable temp        : integer;
    variable temp_bit5   : integer;
    variable temp_bit4   : integer;
    variable temp_bit3   : integer;
    variable temp_bit2   : integer;
    variable temp_bit1   : integer;
    variable temp_bit0   : integer;
    variable group1_zero : boolean;
    variable group2_zero : boolean;
    variable errored1    : integer := 0;
    variable onehot_error: integer := 0;
    
    -- Random bit generator
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Random integer generator
    function random_int return integer is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(2**31)));
    end function;
    
  begin
    -- Initialize
    y <= "000000";
    w <= '0';
    sim_done <= false;
    
    wait for 10 ps;
    
    -- Test one-hot cases first
    -- Matches Verilog: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Matches Verilog: y <= 1 << ($unsigned($random) % 6);
      rand_int := abs(random_int) mod 6;
      y <= std_logic_vector(shift_left(to_unsigned(1, 6), rand_int));
      
      random_bit(w);
      
      -- Track one-hot errors
      if not tb_match then
        onehot_error := onehot_error + 1;
      end if;
    end loop;
    
    -- Random test with mutual exclusivity constraint
    -- Matches Verilog: repeat(400) @(posedge clk, negedge clk)
    errored1 := 0;
    for i in 1 to 400 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      
      -- Generate temp with constraint:
      -- Make y[3,0] and y[5,4,2,1] mutually exclusive
      -- Matches Verilog: do temp = $random; while (!{temp[5:4],temp[2:1]} == !{temp[3],temp[0]});
      loop
        temp := random_int;
        
        -- Extract individual bits
        temp_bit0 := temp mod 2;
        temp_bit1 := (temp / 2) mod 2;
        temp_bit2 := (temp / 4) mod 2;
        temp_bit3 := (temp / 8) mod 2;
        temp_bit4 := (temp / 16) mod 2;
        temp_bit5 := (temp / 32) mod 2;
        
        -- Check groups
        -- group1: {temp[5:4], temp[2:1]} = bits 5,4,2,1
        -- group2: {temp[3], temp[0]} = bits 3,0
        group1_zero := (temp_bit5 = 0) and (temp_bit4 = 0) and (temp_bit2 = 0) and (temp_bit1 = 0);
        group2_zero := (temp_bit3 = 0) and (temp_bit0 = 0);
        
        -- Mutually exclusive: one group zero implies other is non-zero
        -- Exit when: (group1_zero XOR group2_zero) is true
        exit when (group1_zero and not group2_zero) or (not group1_zero and group2_zero);
      end loop;
      
      y <= std_logic_vector(to_unsigned(temp mod 64, 6));
      random_bit(w);
      
      if not tb_match then
        errored1 := errored1 + 1;
      end if;
    end loop;
    
    -- Display hints (informational only in VHDL)
    if onehot_error = 0 and errored1 > 0 then
      report "Hint: Your circuit passed when given only one-hot inputs, but not with semi-random inputs.";
      report "Hint: Are you doing something more complicated than deriving state transition equations by inspection?";
    end if;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;
  end process;

end architecture behavioral;