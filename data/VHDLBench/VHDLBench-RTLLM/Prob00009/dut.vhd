-- (2) DUT implementation (TopModule)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity div_16bit is
  port (
    A      : in  std_logic_vector(15 downto 0);
    B      : in  std_logic_vector(7 downto 0);
    result : out std_logic_vector(15 downto 0);
    odd    : out std_logic_vector(15 downto 0)
  );
end entity div_16bit;

architecture rtl of div_16bit is
  signal a_reg : unsigned(15 downto 0);
  signal b_reg : unsigned(15 downto 0);
  signal tmp_a : unsigned(31 downto 0);
  signal tmp_b : unsigned(31 downto 0);
  
begin

  -- First combinational block: update registers
  process(A, B)
  begin
    a_reg <= unsigned(A);
    b_reg <= resize(unsigned(B), 16);
  end process;
  
  -- Second combinational block: perform division
  process(A, B, a_reg, b_reg)
    variable tmp_a_var : unsigned(31 downto 0);
    variable tmp_b_var : unsigned(31 downto 0);
  begin
    -- Initialize temporary variables
    tmp_a_var := resize(a_reg, 32);  -- {16'b0, a_reg}
    tmp_b_var := b_reg & x"0000";    -- {b_reg, 16'b0}
    
    -- Perform 16 iterations of division algorithm
    for i in 0 to 15 loop
      tmp_a_var := tmp_a_var(30 downto 0) & '0';  -- Left shift by 1
      
      if tmp_a_var >= tmp_b_var then
        tmp_a_var := tmp_a_var - tmp_b_var + 1;
      end if;
    end loop;
    
    tmp_a <= tmp_a_var;
    tmp_b <= tmp_b_var;
  end process;
  
  -- Assign outputs
  odd <= std_logic_vector(tmp_a(31 downto 16));
  result <= std_logic_vector(tmp_a(15 downto 0));

end architecture rtl;