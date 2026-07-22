-- (3) Reference implementation (RefModule)
-- Reference Module: D Latch
-- Transparent latch: q follows d when ena is high
-- Implemented using combinational process (matches Verilog always@(*))

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    d   : in  std_logic;
    ena : in  std_logic;
    q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always@(*) begin if (ena) q = d; end
  -- Note: In Verilog, incomplete if statement creates a latch
  -- In VHDL, we must explicitly model this latch behavior
  process(d, ena)
  begin
    if ena = '1' then
      q <= d;
    -- No else clause - this creates latch behavior (q retains value when ena='0')
    end if;
  end process;

end architecture rtl;