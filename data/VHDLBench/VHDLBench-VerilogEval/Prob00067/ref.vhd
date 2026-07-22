-- (3) Reference implementation (RefModule)
-- Reference Module: Decade Counter (0-9)
-- Synchronous reset, enable control
-- Counts 0->9, wraps to 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk     : in  std_logic;
    slowena : in  std_logic;
    reset   : in  std_logic;
    q       : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : unsigned(3 downto 0) := (others => '0');
begin
  
  q <= std_logic_vector(q_reg);
  
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Synchronous reset
        q_reg <= (others => '0');
      elsif slowena = '1' then
        -- Count when enabled
        if q_reg = 9 then
          q_reg <= (others => '0');
        else
          q_reg <= q_reg + 1;
        end if;
      end if;
      -- else: hold value when slowena = '0'
    end if;
  end process;

end architecture rtl;