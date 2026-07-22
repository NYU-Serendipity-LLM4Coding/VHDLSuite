-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 16-bit D Flip-Flop with byte enables and synchronous reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk     : in  std_logic;
    resetn  : in  std_logic;
    byteena : in  std_logic_vector(1 downto 0);
    d       : in  std_logic_vector(15 downto 0);
    q       : out std_logic_vector(15 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(15 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        q_reg <= (others => '0');
      else
        if byteena(0) = '1' then
          q_reg(7 downto 0) <= d(7 downto 0);
        end if;
        
        if byteena(1) = '1' then
          q_reg(15 downto 8) <= d(15 downto 8);
        end if;
      end if;
    end if;
  end process;

end architecture rtl;