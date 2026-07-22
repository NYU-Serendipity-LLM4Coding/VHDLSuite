-- (2) DUT implementation (multi_booth_8bit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_booth_8bit is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    a     : in  std_logic_vector(7 downto 0);
    b     : in  std_logic_vector(7 downto 0);
    p     : out std_logic_vector(15 downto 0);
    rdy   : out std_logic
  );
end entity multi_booth_8bit;

architecture rtl of multi_booth_8bit is
  signal p_reg : signed(15 downto 0);
  signal multiplier : signed(15 downto 0);
  signal multiplicand : signed(15 downto 0);
  signal rdy_reg : std_logic;
  signal ctr : unsigned(4 downto 0);
  
begin

  -- Main process matching Verilog behavior exactly
  process(clk, reset)
  begin
    if reset = '1' then
      -- Async reset - initialize all registers
      rdy_reg <= '0';
      p_reg <= (others => '0');
      ctr <= (others => '0');
      -- Sign-extend a and b to 16 bits: {{8{a[7]}}, a}
      multiplier <= resize(signed(a), 16);
      multiplicand <= resize(signed(b), 16);
      
    elsif rising_edge(clk) then
      if ctr < 16 then
        -- Shift multiplicand left by 1
        multiplicand <= shift_left(multiplicand, 1);
        
        -- If current bit of multiplier is 1, add multiplicand to product
        if multiplier(to_integer(ctr)) = '1' then
          p_reg <= p_reg + multiplicand;
        end if;
        
        -- Increment counter
        ctr <= ctr + 1;
        
      else
        -- Set ready signal when counter reaches 16
        rdy_reg <= '1';
      end if;
    end if;
  end process;
  
  -- Output assignments
  p <= std_logic_vector(p_reg);
  rdy <= rdy_reg;
  
end architecture rtl;