-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 5-bit Galois LFSR with taps at positions 5 and 3

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(4 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg  : std_logic_vector(4 downto 0) := "00001";
  signal q_next : std_logic_vector(4 downto 0);
begin
  
  q <= q_reg;
  
  -- Combinational logic for next state
  process(q_reg)
  begin
    -- Shift right
    q_next(3 downto 0) <= q_reg(4 downto 1);
    
    -- Feedback
    q_next(4) <= q_reg(0);
    
    -- XOR tap at position 2
    q_next(2) <= q_reg(3) xor q_reg(0);
  end process;
  
  -- Sequential logic
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        q_reg <= "00001";
      else
        q_reg <= q_next;
      end if;
    end if;
  end process;

end architecture rtl;