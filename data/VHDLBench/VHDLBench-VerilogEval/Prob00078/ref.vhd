-- (3) Reference implementation (RefModule)
-- Reference Module: Dual-Edge Triggered Flip-Flop
-- Captures 'd' on both rising and falling edges of clock
-- Uses two separate flip-flops (qp for posedge, qn for negedge)
-- Output q is muxed based on clock level

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
  -- Internal registers for positive and negative edge captures
  signal qp : std_logic := '0';
  signal qn : std_logic := '0';
begin
  
  -- Matches Verilog: always @(posedge clk) qp <= d;
  process(clk)
  begin
    if rising_edge(clk) then
      qp <= d;
    end if;
  end process;
  
  -- Matches Verilog: always @(negedge clk) qn <= d;
  process(clk)
  begin
    if falling_edge(clk) then
      qn <= d;
    end if;
  end process;
  
  -- Matches Verilog: always @(*) q <= clk ? qp : qn;
  -- This introduces a delta delay to prevent early q change
  process(clk, qp, qn)
  begin
    if clk = '1' then
      q <= qp;
    else
      q <= qn;
    end if;
  end process;

end architecture rtl;