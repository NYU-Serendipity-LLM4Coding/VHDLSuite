-- (3) Reference implementation (RefModule)
-- Reference Module: 4-digit BCD Counter
-- Counts from 0000 to 9999 in BCD format
-- Synchronous reset, outputs enable signals for each digit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    ena   : out std_logic_vector(3 downto 1);
    q     : out std_logic_vector(15 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(15 downto 0) := (others => '0');
  signal enable : std_logic_vector(3 downto 0);
begin

  q <= q_reg;
  
  -- Matches Verilog: wire [3:0] enable = { q[11:0]==12'h999, q[7:0]==8'h99, q[3:0]==4'h9, 1'b1};
  enable(0) <= '1';
  enable(1) <= '1' when q_reg(3 downto 0) = "1001" else '0';  -- 4'h9
  enable(2) <= '1' when q_reg(7 downto 0) = x"99" else '0';   -- 8'h99
  enable(3) <= '1' when q_reg(11 downto 0) = x"999" else '0'; -- 12'h999
  
  ena <= enable(3 downto 1);
  
  -- Matches Verilog: always @(posedge clk) for (int i=0;i<4;i++)
  process(clk)
  begin
    if rising_edge(clk) then
      -- Process each BCD digit (4 bits each)
      for i in 0 to 3 loop
        -- Extract 4-bit digit: q[i*4 +:4] in Verilog becomes q_reg(i*4+3 downto i*4)
        if reset = '1' or (q_reg(i*4+3 downto i*4) = "1001" and enable(i) = '1') then
          q_reg(i*4+3 downto i*4) <= "0000";
        elsif enable(i) = '1' then
          q_reg(i*4+3 downto i*4) <= std_logic_vector(unsigned(q_reg(i*4+3 downto i*4)) + 1);
        end if;
      end loop;
    end if;
  end process;

end architecture rtl;