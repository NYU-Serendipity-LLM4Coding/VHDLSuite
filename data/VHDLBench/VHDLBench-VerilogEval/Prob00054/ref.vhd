-- (3) Reference implementation (RefModule)
-- Reference Module: Positive Edge Detector (8-bit)
-- Detects 0-to-1 transitions on each bit independently
-- Output is high for one cycle after transition
-- Variable name changes: 'in' -> 'signal_in'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic_vector(7 downto 0);
    pedge     : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: reg [7:0] d_last;
  signal d_last : std_logic_vector(7 downto 0);
  
  -- Matches Verilog: output reg [7:0] pedge;
  signal pedge_reg : std_logic_vector(7 downto 0);
begin
  
  pedge <= pedge_reg;
  
  -- Matches Verilog: always @(posedge clk) begin
  --   d_last <= in;
  --   pedge <= in & ~d_last;
  -- end
  process(clk)
  begin
    if rising_edge(clk) then
      d_last <= signal_in;
      pedge_reg <= signal_in and (not d_last);
    end if;
  end process;

end architecture rtl;