-- (3) Reference implementation (RefModule)
-- Reference Module: Sequential Circuit with Inverted Input
-- Registers the inverted value of 'a' on rising edge of clk
-- q <= NOT a (registered)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    a   : in  std_logic;
    q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(posedge clk) q <= ~a;
  process(clk)
  begin
    if rising_edge(clk) then
      q <= not a;
    end if;
  end process;

end architecture rtl;