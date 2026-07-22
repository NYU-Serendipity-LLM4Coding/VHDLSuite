-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Edge detector with capture on 1-to-0 transitions

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    signal_in  : in  std_logic_vector(31 downto 0);
    signal_out : out std_logic_vector(31 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal d_last  : std_logic_vector(31 downto 0) := (others => '0');
  signal out_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
  
  signal_out <= out_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      d_last <= signal_in;
      
      if reset = '1' then
        out_reg <= (others => '0');
      else
        out_reg <= out_reg or ((not signal_in) and d_last);
      end if;
    end if;
  end process;

end architecture rtl;