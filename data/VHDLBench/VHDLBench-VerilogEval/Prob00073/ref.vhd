-- (3) Reference implementation (RefModule)
-- Reference Module: 16-bit D Flip-Flop with Byte Enables
-- Synchronous active-low reset (resetn)
-- byteena[0] controls d[7:0], byteena[1] controls d[15:8]

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk     : in  std_logic;
    resetn  : in  std_logic;
    byteena : in  std_logic_vector(1 downto 0);
    d       : in  std_logic_vector(15 downto 0);
    q       : out std_logic_vector(15 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(15 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        -- Matches Verilog: if (!resetn) q <= 0;
        q_reg <= (others => '0');
      else
        -- Matches Verilog: if (byteena[0]) q[7:0] <= d[7:0];
        if byteena(0) = '1' then
          q_reg(7 downto 0) <= d(7 downto 0);
        end if;
        
        -- Matches Verilog: if (byteena[1]) q[15:8] <= d[15:8];
        if byteena(1) = '1' then
          q_reg(15 downto 8) <= d(15 downto 8);
        end if;
      end if;
    end if;
  end process;

end architecture rtl;