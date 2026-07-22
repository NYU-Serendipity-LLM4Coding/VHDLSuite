-- (3) Reference implementation (RefModule)
-- Reference Module: XOR Flip-Flop
-- D flip-flop with XOR feedback
-- out <= in XOR out (registered on rising edge of clk)
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: initial out = 0;
  signal out_reg : std_logic := '0';
begin
  
  signal_out <= out_reg;
  
  -- Matches Verilog: always@(posedge clk) out <= in ^ out;
  process(clk)
  begin
    if rising_edge(clk) then
      out_reg <= signal_in xor out_reg;
    end if;
  end process;

end architecture rtl;