-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Rule 90 cellular automaton

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(511 downto 0);
    q    : out std_logic_vector(511 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(511 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        q_reg <= data;
      else
        -- Rule 90: next_state[i] = left_neighbor[i] XOR right_neighbor[i]
        for i in 0 to 511 loop
          if i = 0 then
            q_reg(i) <= '0' xor q_reg(i+1);
          elsif i = 511 then
            q_reg(i) <= q_reg(i-1) xor '0';
          else
            q_reg(i) <= q_reg(i-1) xor q_reg(i+1);
          end if;
        end loop;
      end if;
    end if;
  end process;

end architecture rtl;