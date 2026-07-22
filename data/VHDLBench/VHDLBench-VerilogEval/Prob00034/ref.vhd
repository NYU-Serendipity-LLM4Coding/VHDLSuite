-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit D Flip-Flop
-- Positive edge triggered, no reset
-- Matches Verilog: always @(posedge clk) q <= d;

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    d   : in  std_logic_vector(7 downto 0);
    q   : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: initial q = 8'hx;
  -- Note: VHDL doesn't support 'X' initialization in synthesis,
  -- but we can use it in simulation. For synthesis, it will be ignored.
  signal q_reg : std_logic_vector(7 downto 0) := (others => 'U');
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