-- (3) Reference implementation (RefModule)
-- Reference Module: D Flip-Flop with Active High Synchronous Reset
-- When r=1, output q is reset to 0 on rising edge of clk
-- When r=0, output q takes value of d on rising edge of clk

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    r   : in  std_logic;
    q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always@(posedge clk) begin
  --   if (r) q <= 0;
  --   else q <= d;
  -- end
  process(clk)
  begin
    if rising_edge(clk) then
      if r = '1' then
        q <= '0';
      else
        q <= d;
      end if;
    end if;
  end process;

end architecture rtl;