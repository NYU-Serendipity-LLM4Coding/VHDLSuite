-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit D Flip-Flop with Synchronous Active-High Reset
-- All flip-flops triggered on rising edge of clk
-- When reset=1, output q is set to 0 (synchronously)
-- When reset=0, output q takes value of input d

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
  signal q_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk) if (reset) q <= 0; else q <= d;
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        q_reg <= (others => '0');
      else
        q_reg <= d;
      end if;
    end if;
  end process;

end architecture rtl;