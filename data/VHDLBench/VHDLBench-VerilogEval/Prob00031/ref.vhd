-- (3) Reference implementation (RefModule)
-- Reference Module: D Flip-Flop
-- Positive edge-triggered D flip-flop
-- Matches Verilog: initial q = 1'hx; always @(posedge clk) q <= d;

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: initial q = 1'hx;
  -- In VHDL, 'U' (uninitialized) is the closest equivalent to Verilog 'X'
  signal q_reg : std_logic := 'U';
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk) q <= d;
  process(clk)
  begin
    if rising_edge(clk) then
      q_reg <= d;
    end if;
  end process;

end architecture rtl;