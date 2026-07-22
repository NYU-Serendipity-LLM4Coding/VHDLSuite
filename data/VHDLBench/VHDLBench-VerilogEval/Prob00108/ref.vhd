-- (3) Reference implementation (RefModule)
-- Reference Module: Rule 90 Cellular Automaton
-- 512-cell system with XOR-based neighbor rules
-- Matches Verilog: q <= q[510:1] ^ {q[509:0], 1'b0}
-- This shifts right by 1 and XORs with left shift by 1

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(511 downto 0);
    q    : out std_logic_vector(511 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(511 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        q_reg <= data;
      else
        -- Matches Verilog: q <= q[$bits(q)-1:1] ^ {q[$bits(q)-2:0], 1'b0}
        -- q[511:1] is right neighbor (shifted right)
        -- {q[510:0], 1'b0} is left neighbor (shifted left with 0 at LSB)
        -- Rule 90: next_state[i] = q[i-1] XOR q[i+1]
        -- Boundary conditions: q[-1] = 0, q[512] = 0
        
        for i in 0 to 511 loop
          if i = 0 then
            -- Left boundary: q[-1] = 0, so XOR with q[1]
            q_reg(i) <= '0' xor q_reg(i+1);
          elsif i = 511 then
            -- Right boundary: q[512] = 0, so XOR with q[510]
            q_reg(i) <= q_reg(i-1) xor '0';
          else
            -- Normal case: XOR left and right neighbors
            q_reg(i) <= q_reg(i-1) xor q_reg(i+1);
          end if;
        end loop;
      end if;
    end if;
  end process;

end architecture rtl;