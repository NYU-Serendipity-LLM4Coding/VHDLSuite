-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit Edge Detector
-- Detects any edge (0->1 or 1->0) on each bit
-- Output is set the cycle after transition occurs
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic_vector(7 downto 0);
    anyedge   : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: reg [7:0] d_last;
  signal d_last : std_logic_vector(7 downto 0);
  
begin

  -- Matches Verilog: always @(posedge clk) begin
  --                     d_last <= in;
  --                     anyedge <= in ^ d_last;
  --                   end
  process(clk)
  begin
    if rising_edge(clk) then
      d_last  <= signal_in;
      anyedge <= signal_in xor d_last;
    end if;
  end process;

end architecture rtl;