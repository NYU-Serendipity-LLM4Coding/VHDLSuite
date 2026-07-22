-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 32-bit Galois LFSR
-- Taps at bit positions 32, 22, 2, and 1
-- Synchronous active-high reset to 32'h1

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(31 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(31 downto 0) := (0 => '1', others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
    variable q_next : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if reset = '1' then
        q_reg <= (0 => '1', others => '0');
      else
        -- Right shift
        q_next := '0' & q_reg(31 downto 1);
        
        -- Wrap LSB to MSB (tap at position 32)
        q_next(31) := q_reg(0);
        
        -- Apply taps: XOR with LSB
        q_next(21) := q_next(21) xor q_reg(0);  -- Tap at position 22
        q_next(1)  := q_next(1)  xor q_reg(0);  -- Tap at position 2
        q_next(0)  := q_next(0)  xor q_reg(0);  -- Tap at position 1
        
        q_reg <= q_next;
      end if;
    end if;
  end process;

end architecture rtl;