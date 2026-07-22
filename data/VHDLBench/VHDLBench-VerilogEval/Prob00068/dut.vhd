-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 4-digit BCD counter with synchronous reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    ena   : out std_logic_vector(3 downto 1);
    q     : out std_logic_vector(15 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(15 downto 0) := (others => '0');
  signal enable : std_logic_vector(3 downto 0);
begin

  q <= q_reg;
  
  -- Generate enable signals for each digit
  enable(0) <= '1';
  enable(1) <= '1' when q_reg(3 downto 0) = "1001" else '0';
  enable(2) <= '1' when q_reg(7 downto 0) = x"99" else '0';
  enable(3) <= '1' when q_reg(11 downto 0) = x"999" else '0';
  
  ena <= enable(3 downto 1);
  
  -- BCD counter with synchronous reset
  process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 3 loop
        if reset = '1' or (q_reg(i*4+3 downto i*4) = "1001" and enable(i) = '1') then
          q_reg(i*4+3 downto i*4) <= "0000";
        elsif enable(i) = '1' then
          q_reg(i*4+3 downto i*4) <= std_logic_vector(unsigned(q_reg(i*4+3 downto i*4)) + 1);
        end if;
      end loop;
    end if;
  end process;

end architecture rtl;