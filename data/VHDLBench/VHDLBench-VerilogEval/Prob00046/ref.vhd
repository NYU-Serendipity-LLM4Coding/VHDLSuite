-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit D Flip-Flop with Synchronous Reset
-- Negative edge triggered, resets to 0x34 when reset is high
-- Corresponds to Verilog module: RefModule

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    d     : in  std_logic_vector(7 downto 0);
    reset : in  std_logic;
    q     : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: output reg [7:0] q
  signal q_reg : std_logic_vector(7 downto 0) := x"00";
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(negedge clk)
  --   if (reset) q <= 8'h34; else q <= d;
  process(clk)
  begin
    if falling_edge(clk) then
      if reset = '1' then
        q_reg <= x"34";  -- Reset value 0x34
      else
        q_reg <= d;
      end if;
    end if;
  end process;

end architecture rtl;